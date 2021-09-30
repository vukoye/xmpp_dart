import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChat.dart';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;

import 'personel.dart';

final String TAG = 'manager';

class XMPPClientManager {
  XMPPClientPersonel personel;
  Function(XMPPClientManager _context) _onReady;
  xmpp.Connection _connection;
  XMPPClientManager(jid, password, void Function(XMPPClientManager _context) _onReady) {
    personel = XMPPClientPersonel(jid, password);
    this._onReady = _onReady;
  }

  XMPPClientManager createSession() {
    Log.logLevel = LogLevel.DEBUG;
    Log.logXmpp = false;

    var jid = xmpp.Jid.fromFullJid(personel.jid);
    var account = xmpp.XmppAccountSettings(personel.jid, jid.local, jid.domain, personel.password, 5222); // , resource: 'xmppstone'
    _connection = xmpp.Connection(account);
    _connection.connect();

    return this;
  }

  void onReady() {
    _onReady(this);
  }

  // My Profile
  void vCardRead() {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        personel.profile = vCard;
        Log.d(TAG, 'Your info' + vCard.buildXmlString());
      }
    });
  }

  void vCardUpdate(xmpp.VCard Function(xmpp.VCard vCardToUpdate) _onUpdate) {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        Log.d(TAG, 'manager.vCardUpdate::my info ' + vCard.buildXmlString());
      }
      // Update vcard information
      var _vCardUpdated = _onUpdate(vCard);
      Log.d(TAG, 'manager.vCardUpdate::my updated info ' + _vCardUpdated.buildXmlString());
      vCardManager.updateSelfVCard(_vCardUpdated).then((updatedAckVCard) {
        personel.profile = _vCardUpdated;
        Log.d(TAG, 'manager.vCardUpdate::my updated info - Updated info success');
      });
    });
  }

  // My contact/buddy
  void vCardFrom(receiver) {
    var receiverJid = xmpp.Jid.fromFullJid(receiver);
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getVCardFor(receiverJid).then((vCard) {
      if (vCard != null) {
        Log.d(TAG, 'Receiver info' + vCard.buildXmlString());
        // if (vCard != null && vCard.image != null) {
        //   var file = File('test456789.jpg')..writeAsBytesSync(image.encodeJpg(vCard.image));
        //   Log.d(TAG, 'IMAGE SAVED TO: ${file.path}');
        // }
      } else {
        Log.d(TAG, 'manager.vCardFrom: failed');
      }
    });
  }

  // Get roster list
  void rosterList() {

    var rosterManager = xmpp.RosterManager.getInstance(_connection);
    rosterManager.queryForRoster().then((result) {
      var rosterList = rosterManager.getRoster();
      personel.buddies = rosterList;
      Log.d(TAG, 'manager.rosterList.rosterList: ' + rosterList.length.toString());
    });
  }

  // Add friend
  void rosterAdd(receiver) {
    var receiverJid = xmpp.Jid.fromFullJid(receiver);

    var rosterManager = xmpp.RosterManager.getInstance(_connection);
    rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
      if (result.description != null) {
        Log.d(TAG, 'add roster' + result.description);
        // Refresh the list
        rosterList();
      }
    });
  }

  // Multi user chat

  // Add the callback or await?
  void mucDiscover(String domain) {
    var mucManager = xmpp.MultiUserChatManager(_connection);
    mucManager.discoverMucService(xmpp.Jid('', domain, '')).then((MultiUserChat muc) {
      
      if (muc != null) {
        print('MUC response success');
        print(muc);
      } else {
        print('MUC response not found or error');
      }
      
    });
  }

  void listens() {
    _listenMessage();
    _listenPresence();
  }

  void _listenMessage() {

    xmpp.MessagesListener messagesListener = ClientMessagesListener();
    ConnectionManagerStateChangedListener(_connection, messagesListener, this);
  }
  void _listenPresence() {
    var presenceManager = xmpp.PresenceManager.getInstance(_connection);
    presenceManager.subscriptionStream.listen((streamEvent) {
      print(streamEvent.type.toString() + 'stream type');
      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
        Log.d(TAG, 'Accepting presence request');
        presenceManager.acceptSubscription(streamEvent.jid);
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

class ConnectionManagerStateChangedListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  XMPPClientManager _context;

  StreamSubscription<String> subscription;

  ConnectionManagerStateChangedListener(xmpp.Connection connection, xmpp.MessagesListener messagesListener, XMPPClientManager context) {
    _connection = connection;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
    _context = context;
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      Log.d(TAG, 'Connected');
      _context.onReady();
    }
  }

  void onPresence(xmpp.PresenceData event) {
    Log.d(TAG, 'presence Event from ' + event.jid.fullJid + ' PRESENCE: ' + event.showElement.toString());
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
      Log.d(TAG, format(
          'New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}'));
    }
  }
}
