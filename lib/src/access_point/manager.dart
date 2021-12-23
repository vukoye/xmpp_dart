import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone_obelisk/src/access_point/manager_message_params.dart';
import 'package:xmpp_stone_obelisk/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/ReceiptInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/multi_user_chat/MultiUserChatData.dart';
import 'package:xmpp_stone_obelisk/src/logger/Log.dart';
import 'package:xmpp_stone_obelisk/src/messages/MessageHandler.dart';
import 'package:xmpp_stone_obelisk/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;
import 'package:intl/intl.dart';

import 'personel.dart';

final String TAG = 'manager::general';

enum MessageDelivery { UNKNOWN, DIRECT, STORED, ONLINE }

enum ListenerType {
  onReady,
  onLog,
  onPresence,
  onMessage,
  onMessage_Custom,
  onMessage_Sent,
  onMessage_Delivered_Direct,
  onMessage_Delivered_Stored,
  onMessage_Delivered_Client,
  onMessage_Read_Client,
  onMessage_Carbon,
  onMessage_Delayed,
}

class XMPPClientManager {
  String LOG_TAG = 'XMPPClientManager';
  String? host;
  String? mucDomain = '';
  late XMPPClientPersonel personel;
  Function(XMPPClientManager _context)? _onReady;
  Function(String timestamp, String logMessage)? _onLog;
  Function(xmpp.MessageStanza message, ListenerType listenerType)? _onMessage;
  Function(xmpp.SubscriptionEvent event)? _onPresenceSubscription;
  Function(xmpp.PresenceData event)? _onPresence;
  xmpp.Connection? _connection;
  late MessageHandler _messageHandler;

  StreamSubscription? messageListener;

  XMPPClientManager(jid, password,
      {void Function(XMPPClientManager _context)? onReady,
      void Function(String _timestamp, String _message)? onLog,
      void Function(xmpp.MessageStanza message, ListenerType listenerType)?
          onMessage,
      void Function(xmpp.SubscriptionEvent event)? onPresenceSubscription,
      void Function(xmpp.PresenceData event)? onPresence,
      String? host,
      String? this.mucDomain}) {
    personel = XMPPClientPersonel(jid, password);
    LOG_TAG = '$LOG_TAG/$jid';
    _onReady = onReady;
    _onLog = onLog;
    _onMessage = onMessage;
    _onPresence = onPresence;
    _onPresenceSubscription = onPresenceSubscription;
    this.host = host;
  }

  XMPPClientManager createSession() {
    Log.logLevel = LogLevel.DEBUG;
    Log.logXmpp = false;
    var jid = xmpp.Jid.fromFullJid(personel.jid);
    Log.d(LOG_TAG, 'Connecting to $host');
    var account = xmpp.XmppAccountSettings(
        personel.jid, jid.local, jid.domain, personel.password, 5222,
        mucDomain: mucDomain, host: host);
    _connection = xmpp.Connection(account);
    _connection!.connect();
    _listenConnection();
    onLog('Start connecting');
    return this;
  }

  getState() {
    return _connection!.state;
  }

  lookForConnection() {
    if (_connection!.state == xmpp.XmppConnectionState.ForcefullyClosed) {
      _connection!.reconnect();
    } else if (_connection!.state == xmpp.XmppConnectionState.Closed) {
      _connection!.connect();
    } else if (_connection!.state == xmpp.XmppConnectionState.Closing) {
      _connection!.close();
      _connection!.connect();
    }
    return getState();
  }

  void onReady() {
    onLog('Connected');
    _messageHandler = xmpp.MessageHandler.getInstance(_connection);
    _onReady!(this);
  }

  void onLog(String message) {
    _onLog!(DateFormat('yyyy-MM-dd kk:mm').format(DateTime.now()), message);
    Log.i(LOG_TAG, message);
  }

  // My Profile
  void vCardRead() {
    var vCardManager = xmpp.VCardManager(_connection!);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        personel.profile = vCard;

        onLog('Your info' + vCard.buildXmlString());
      }
    });
  }

  void vCardUpdate(xmpp.VCard Function(xmpp.VCard vCardToUpdate) _onUpdate) {
    var vCardManager = xmpp.VCardManager(_connection!);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        onLog('manager.vCardUpdate::my info ${vCard.buildXmlString()}');
      }
      // Update vcard information
      var _vCardUpdated = _onUpdate(vCard);

      onLog(
          'manager.vCardUpdate::my updated info ${_vCardUpdated.buildXmlString()}');
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
    var vCardManager = xmpp.VCardManager(_connection!);
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
        onLog('add roster' + result.description!);
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
        onLog('remove roster' + result.description!);
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
  Future<GroupChatroom> getRoom(String roomName) {
    var mucManager = xmpp.MultiUserChatManager(_connection!);
    return mucManager.discoverRoom(xmpp.Jid(roomName, mucDomain, ''));
  }

  // Add the callback or await?
  Future<GroupChatroom> getReservedRoomConfig(String roomName) {
    var mucManager = xmpp.MultiUserChatManager(_connection!);
    return mucManager
        .requestReservedRoomConfig(xmpp.Jid(roomName, mucDomain, ''));
  }

  // Create room
  Future<GroupChatroom> setRoomConfig(
      String roomName, GroupChatroomConfig config) {
    var mucManager = xmpp.MultiUserChatManager(_connection!);
    return mucManager.setRoomConfig(xmpp.Jid(roomName, mucDomain, ''), config);
  }

  // Create room
  Future<GroupChatroom> createInstantRoom(
      String roomName, GroupChatroomConfig config) {
    var mucManager = xmpp.MultiUserChatManager(_connection!);
    return mucManager.createRoom(xmpp.Jid(roomName, mucDomain, ''), config);
  }

  // Send 1-1 feature discovery
  void discoverMessageDelivery(String sender, String receiver) {
    var mucManager = xmpp.MessageDeliveryManager(_connection!);
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
      {int? time, required String messageId, String customString = ''}) {
    return _messageHandler.sendMessage(xmpp.Jid.fromFullJid(receiver), message,
        millisecondTs: time,
        receipt: xmpp.ReceiptRequestType.REQUEST,
        messageId: messageId,
        customString: customString);
  }

  Future<xmpp.MessageStanza> sendDeliveryAck(xmpp.MessageStanza message) {
    return _messageHandler.sendMessage(message.fromJid, '',
        messageId: message.id!, receipt: xmpp.ReceiptRequestType.RECEIVED);
  }

  void listens() {
    _listenMessage();
    _listenPresence();
  }

  void _listenMessage() {
    Log.d(LOG_TAG, 'Start listening');
    if (messageListener != null) {
      messageListener!.cancel();
    }
    messageListener =
        _messageHandler.messagesStream.listen((xmpp.MessageStanza? message) {
      var _messageWrapped = XMPPMessageParams(message: message);

      // TODO: Simplify the condition
      if (_messageWrapped.isCarbon) {
        _onMessage!(_messageWrapped.message!, ListenerType.onMessage_Carbon);
        Log.i(
            LOG_TAG, 'New `ListenerType.onMessage_Carbon` from ${message!.id}');
      }
      if (_messageWrapped.isDelay) {
        _onMessage!(_messageWrapped.message!, ListenerType.onMessage_Delayed);
        Log.i(LOG_TAG,
            'New `ListenerType.onMessage_Delayed` from ${message!.id}');
      }
      if (_messageWrapped.isAckDeliveryDirect) {
        _onMessage!(
            _messageWrapped.message!, ListenerType.onMessage_Delivered_Direct);
        Log.i(LOG_TAG,
            'New `ListenerType.onMessage_Delivered_Direct` from ${message!.id}');
      }
      if (_messageWrapped.isAckDeliveryStored) {
        _onMessage!(
            _messageWrapped.message!, ListenerType.onMessage_Delivered_Stored);
        Log.i(LOG_TAG,
            'New `ListenerType.onMessage_Delivered_Stored` from ${message!.id}');
      }
      if (_messageWrapped.isAckDeliveryClient) {
        _onMessage!(
            _messageWrapped.message!, ListenerType.onMessage_Delivered_Client);
        Log.i(LOG_TAG,
            'New `ListenerType.onMessage_Delivered_Client` from ${message!.id}');
      }
      if (_messageWrapped.isAckReadClient) {
        _onMessage!(
            _messageWrapped.message!, ListenerType.onMessage_Read_Client);
        Log.i(LOG_TAG,
            'New `ListenerType.onMessage_Read_Client` from ${message!.id}');
      }
      if (_messageWrapped.isOnlyMessage) {
        if (_messageWrapped.isMessageCustom) {
          _onMessage!(_messageWrapped.message!, ListenerType.onMessage_Custom);
          Log.i(LOG_TAG,
              'New `ListenerType.onMessage_Custom` from ${message!.id}');
        }
        if (_messageWrapped.isMessage) {
          _onMessage!(_messageWrapped.message!, ListenerType.onMessage);
          Log.i(LOG_TAG, 'New `ListenerType.onMessage` from ${message!.id}');
        }
      }

      // Send receipt if request
      if (_messageWrapped.isRequestingReceipt) {
        sendDeliveryAck(message!);
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
      _onPresence!(presenceTypeEvent);
      onLog('Presence status: ' +
          presenceTypeEvent.jid!.fullJid! +
          ': ' +
          presenceTypeEvent.showElement.toString());
    });
    presenceManager.subscriptionStream.listen((streamEvent) {
      _onPresenceSubscription!(streamEvent);
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
  xmpp.Connection? _connection;
  late XMPPClientManager _context;

  StreamSubscription<String>? subscription;

  ConnectionManagerStateChangedListener(xmpp.Connection? connection,
      xmpp.MessagesListener messagesListener, XMPPClientManager context) {
    _connection = connection;
    _connection!.connectionStateStream.listen(onConnectionStateChanged);
    _context = context;
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Authenticated) {
      Log.i(_context.LOG_TAG, 'Connected');
      _context.onReady();
    } else if (state == xmpp.XmppConnectionState.Closed) {
      Log.i(_context.LOG_TAG, 'Disconnected');
      _context._connection!.connect();
    }
  }

  void onPresence(xmpp.PresenceData event) {
    Log.i(
        _context.LOG_TAG,
        'presence Event from ' +
            event.jid!.fullJid! +
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
  void onNewMessage(xmpp.MessageStanza? message) {
    if (message!.body != null) {
      Log.i(
          TAG,
          format(
              'New Message from {color.blue}${message.fromJid!.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}'));
    }
  }
}
