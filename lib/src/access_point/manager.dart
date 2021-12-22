import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChat.dart';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/src/messages/MessageHandler.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;
import 'package:intl/intl.dart';

import 'personel.dart';

final String TAG = 'manager::general';

enum MessageDelivery { UNKNOWN, DIRECT, STORED, ONLINE }

class XMPPMessageParams {
  final xmpp.MessageStanza original;
  const XMPPMessageParams({this.original});

  xmpp.MessageStanza get message {
    if (original.body != null) {
      return original;
    } else {
      return null;
    }
  }

  xmpp.MessageStanza get customMessage {
    if (original.body == null && original.getCustom() != null) {
      return original;
    } else {
      return null;
    }
  }

  xmpp.MessageStanza get ackDeliveryDirect {
    if (original.body == null && original.isAmpDeliverDirect()) {
      return original;
    } else {
      return null;
    }
  }

  xmpp.MessageStanza get ackDeliveryStored {
    if (original.body == null && original.isAmpDeliverStore()) {
      return original;
    } else {
      return null;
    }
  }

  xmpp.MessageStanza get ackDeliveryClient {
    if (original.body == null &&
        original.getCustom() == null &&
        !original.isAmpDeliverStore() &&
        !original.isAmpDeliverDirect() &&
        original.fromJid.isValid() &&
        original.toJid.isValid()) {
      return original;
    } else {
      return null;
    }
  }

  xmpp.MessageStanza get ackReadClient {
    if (original.body == null &&
        original.getCustom() != null &&
        getCustomData['iqType'] == 'Read-Ack') {
      return original;
    } else {
      return null;
    }
  }

  Map<String, dynamic> get getCustomData {
    if (customMessage != null && customMessage.getCustom() != null) {
      return json.decode(customMessage.getCustom().textValue);
    } else {
      return {};
    }
  }
}

class XMPPClientManager {
  String LOG_TAG = 'manager';
  String host;
  XMPPClientPersonel personel;
  Function(XMPPClientManager _context) _onReady;
  Function(String timestamp, String logMessage) _onLog;
  Function(xmpp.MessageStanza message) _onMessage;
  Function(xmpp.MessageStanza message, MessageDelivery delivery)
      _onMessageDelivery;
  Function(xmpp.MessageStanza message) _onMessageRead;
  Function(xmpp.SubscriptionEvent event) _onPresenceSubscription;
  Function(xmpp.PresenceData event) _onPresence;
  xmpp.Connection _connection;
  MessageHandler _messageHandler;

  XMPPClientManager(jid, password,
      {void Function(XMPPClientManager _context) onReady,
      void Function(String _timestamp, String _message) onLog,
      void Function(xmpp.MessageStanza message) onMessage,
      void Function(xmpp.MessageStanza message, MessageDelivery delivery)
          onMessageDelivery,
      void Function(xmpp.MessageStanza message) onMessageRead,
      void Function(xmpp.SubscriptionEvent event) onPresenceSubscription,
      void Function(xmpp.PresenceData event) onPresence,
      String host}) {
    personel = XMPPClientPersonel(jid, password);
    LOG_TAG = 'manager::$jid';
    _onReady = onReady;
    _onLog = onLog;
    _onMessage = onMessage;
    _onMessageDelivery = onMessageDelivery;
    _onMessageRead = onMessageRead;
    _onPresence = onPresence;
    _onPresenceSubscription = onPresenceSubscription;
    this.host = host;
  }

  XMPPClientManager createSession() {
    Log.logLevel = LogLevel.DEBUG;
    Log.logXmpp = false;
    var jid = xmpp.Jid.fromFullJid(personel.jid);
    print('connecting to' + host);
    var account = xmpp.XmppAccountSettings(
        personel.jid, jid.local, jid.domain, personel.password, 5222,
        host: host); // , resource: 'xmppstone'
    _connection = xmpp.Connection(account);
    _connection.connect();
    _listenConnection();
    onLog('Start connecting');
    return this;
  }

  void onReady() {
    onLog('Connected');
    _messageHandler = xmpp.MessageHandler.getInstance(_connection);
    _onReady(this);
  }

  void onLog(String message) {
    _onLog(DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now()), message);
    Log.i(LOG_TAG, message);
  }

  // My Profile
  void vCardRead() {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        personel.profile = vCard;

        onLog('Your info' + vCard.buildXmlString());
      }
    });
  }

  void vCardUpdate(xmpp.VCard Function(xmpp.VCard vCardToUpdate) _onUpdate) {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        onLog('manager.vCardUpdate::my info ' + vCard.buildXmlString());
      }
      // Update vcard information
      var _vCardUpdated = _onUpdate(vCard);

      onLog('manager.vCardUpdate::my updated info ' +
          _vCardUpdated.buildXmlString());
      vCardManager.updateSelfVCard(_vCardUpdated).then((updatedAckVCard) {
        personel.profile = _vCardUpdated;
        onLog('manager.vCardUpdate::my updated info - Updated info success');
      });
    });
  }

  // Update presence and status
  void presenceSend() {
    var presenceManager = xmpp.PresenceManager.getInstance(_connection);
    var presenceData = xmpp.PresenceData(PresenceShowElement.CHAT, 'Working',
        xmpp.Jid.fromFullJid(personel.jid));
    presenceManager.sendPresence(presenceData);
  }

  void presenceFrom(receiver) {
    var jid = xmpp.Jid.fromFullJid(receiver);
    var presenceManager = xmpp.PresenceManager.getInstance(_connection);
    presenceManager.askDirectPresence(jid);
  }

  // My contact/buddy
  void vCardFrom(receiver) {
    var receiverJid = xmpp.Jid.fromFullJid(receiver);
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getVCardFor(receiverJid).then((vCard) {
      if (vCard != null) {
        onLog('Receiver info' + vCard.buildXmlString());
        // if (vCard != null && vCard.image != null) {
        //   var file = File('test456789.jpg')..writeAsBytesSync(image.encodeJpg(vCard.image));
        //   Log.i(LOG_TAG, 'IMAGE SAVED TO: ${file.path}');
        // }
      } else {
        onLog('manager.vCardFrom: failed');
      }
    });
  }

  // Get roster list
  Future<List<xmpp.Buddy>> rosterList() {
    var completer = Completer<List<xmpp.Buddy>>();
    var rosterManager = xmpp.RosterManager.getInstance(_connection);
    rosterManager.queryForRoster().then((result) {
      var rosterList = rosterManager.getRoster();
      personel.buddies = rosterList;
      completer.complete(rosterList);
    });
    return completer.future;
  }

  // Add friend
  Future<List<xmpp.Buddy>> rosterAdd(receiver) {
    var completer = Completer<List<xmpp.Buddy>>();
    var receiverJid = xmpp.Jid.fromFullJid(receiver);

    var rosterManager = xmpp.RosterManager.getInstance(_connection);
    rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
      if (result.description != null) {
        onLog('add roster' + result.description);
        // Refresh the list
        rosterList().then((rosterList) {
          completer.complete(rosterList);
        });
      } else {
        onLog('add roster error');
      }
    });
    return completer.future;
  }

  Future<List<xmpp.Buddy>> rosterRemove(receiver) {
    var completer = Completer<List<xmpp.Buddy>>();
    var receiverJid = xmpp.Jid.fromFullJid(receiver);

    var rosterManager = xmpp.RosterManager.getInstance(_connection);
    rosterManager.removeRosterItem(xmpp.Buddy(receiverJid)).then((result) {
      if (result.description != null) {
        onLog('remove roster' + result.description);
        // Refresh the list
        rosterList().then((rosterList) {
          completer.complete(rosterList);
        });
      } else {
        onLog('remove roster error');
      }
    });
    return completer.future;
  }

  // Multi user chat

  // Add the callback or await?
  void mucDiscover(String domain) {
    var mucManager = xmpp.MultiUserChatManager(_connection);
    mucManager
        .discoverMucService(xmpp.Jid('', domain, ''))
        .then((MultiUserChat muc) {
      if (muc != null) {
        onLog('MUC response success');
      } else {
        onLog('MUC response not found or error');
      }
    });
  }

  // Send 1-1 feature discovery
  void discoverMessageDelivery(String sender, String receiver) {
    var mucManager = xmpp.MessageDeliveryManager(_connection);
    mucManager
        .discoverDeliveryFeature(
            xmpp.Jid.fromFullJid(sender), xmpp.Jid.fromFullJid(receiver))
        .then((String result) {
      if (result != null) {
        onLog('Discovery failed response success');
      } else {
        onLog('Discover success: ' + result);
      }
    });
  }

  // Send 1-1 message
  Future<xmpp.MessageStanza> sendMessage(String message, String receiver,
      {int time, String messageId, String customString = ''}) {
    return _messageHandler.sendMessage(xmpp.Jid.fromFullJid(receiver), message,
        millisecondTs: time,
        receipt: xmpp.ReceiptRequestType.REQUEST,
        messageId: messageId,
        customString: customString);
  }

  void sendDeliveryAck(xmpp.MessageStanza message) {
    _messageHandler.sendMessage(message.fromJid, '',
        messageId: message.id, receipt: xmpp.ReceiptRequestType.RECEIVED);
  }

  void listens() {
    _listenMessage();
    _listenPresence();
  }

  void _listenMessage() {
    print('================start listine');
    _messageHandler.messagesStream.listen((xmpp.MessageStanza message) {
      var _messageWrapped = XMPPMessageParams(original: message);
      if (_messageWrapped.message != null) {
        _onMessage(message);
        // Check if delivery receipt request?
        sendDeliveryAck(message);
        Log.i(
            TAG,
            format(
                'New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end} - ${message.id}'));
      } else if (_messageWrapped.ackDeliveryDirect != null) {
        Log.d(TAG, 'Message delivered to client resource');
        // Acknowledgement sent direct to client
        _onMessageDelivery(
            _messageWrapped.ackDeliveryDirect, MessageDelivery.DIRECT);
      } else if (_messageWrapped.ackDeliveryStored != null) {
        Log.d(TAG, 'Message delivered to offline storage resource');
        // Acknowledgement after stored in offline storage
        _onMessageDelivery(
            _messageWrapped.ackDeliveryStored, MessageDelivery.STORED);
      } else if (_messageWrapped.ackDeliveryClient != null) {
        Log.d(TAG, 'Message delivered to client device after online?');
        // Acknowledgement sent by client device
        _onMessageDelivery(
            _messageWrapped.ackDeliveryClient, MessageDelivery.ONLINE);
      } else if (_messageWrapped.customMessage != null) {
        sendDeliveryAck(message);
        if (_messageWrapped.ackReadClient != null) {
          Log.d(TAG,
              'Read ack received - ${_messageWrapped.customMessage.getCustom().buildXmlString()}');
          _onMessageRead(_messageWrapped.ackReadClient);
        } else {
          Log.d(TAG,
              'Custom Message received - ${_messageWrapped.customMessage.getCustom().buildXmlString()}');
        }
      }
    });
  }

  void _listenConnection() {
    xmpp.MessagesListener messagesListener = ClientMessagesListener();
    ConnectionManagerStateChangedListener(_connection, messagesListener, this);
  }

  void _listenPresence() {
    var presenceManager = xmpp.PresenceManager.getInstance(_connection);
    presenceManager.presenceStream.listen((presenceTypeEvent) {
      _onPresence(presenceTypeEvent);
      onLog('Presence status: ' +
          presenceTypeEvent.jid.fullJid +
          ': ' +
          presenceTypeEvent.showElement.toString());
    });
    presenceManager.subscriptionStream.listen((streamEvent) {
      print(streamEvent.type.toString() + 'stream type');

      _onPresenceSubscription(streamEvent);
      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
        onLog('Accepting presence request');
        presenceManager.acceptSubscription(streamEvent.jid);
      } else if (streamEvent.type == xmpp.SubscriptionEventType.ACCEPTED) {
        onLog('Acccepted presence request');
        // presenceManager.acceptSubscription(streamEvent.jid);
      }
    });
  }

  // void readSessionLogs() {

  //   var receiver = C_RECEIVER;
  //   var receiverJid = xmpp.Jid.fromFullJid(receiver);
  //   var messageHandler = xmpp.MessageHandler.getInstance(_connection);
  //   print(receiverJid.local + ', ' + receiverJid.domain);
  //   getConsoleStream().asBroadcastStream().listen((String str) {
  //     print('receive jid: ' + str);
  //     messageHandler.sendMessage(receiverJid, str);
  //   });
  // }
}

class ConnectionManagerStateChangedListener
    implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  XMPPClientManager _context;

  StreamSubscription<String> subscription;

  ConnectionManagerStateChangedListener(xmpp.Connection connection,
      xmpp.MessagesListener messagesListener, XMPPClientManager context) {
    _connection = connection;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
    _context = context;
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Authenticated) {
      Log.i(_context.LOG_TAG, 'Connected');
      _context.onReady();
    }
  }

  void onPresence(xmpp.PresenceData event) {
    Log.i(
        _context.LOG_TAG,
        'presence Event from ' +
            event.jid.fullJid +
            ' PRESENCE: ' +
            event.showElement.toString());
  }
}

Stream<String> getConsoleStream() {
  return Console.adapter.byteStream().map((bytes) {
    var str = ascii.decode(bytes);
    str = str.substring(0, str.length - 1);
    return str;
  });
}

class ClientMessagesListener implements xmpp.MessagesListener {
  @override
  void onNewMessage(xmpp.MessageStanza message) {
    if (message.body != null) {
      Log.i(
          TAG,
          format(
              'New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}'));
    }
  }
}
