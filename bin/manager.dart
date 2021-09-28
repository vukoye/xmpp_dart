import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;

final String TAG = 'example';
// Sean side - 0
final String C_RECEIVER = 'alice@localhost';
final String C_SENDER = 'sean@localhost';

// Alice side - 1
// final String C_SENDER = 'alice@localhost';
// final String C_RECEIVER = 'sean@localhost';

class XMPPClientManager {
  String jid;
  String password;
  Function(XMPPClientManager _context) _onReady;
  xmpp.Connection _connection;
  XMPPClientManager(jid, password, void Function(XMPPClientManager _context) _onReady) {
    this.jid = jid;
    this.password = password;
    this._onReady = _onReady;
  }

  XMPPClientManager createSession() {
    Log.logLevel = LogLevel.DEBUG;
    Log.logXmpp = false;
    Log.d(TAG, 'Create session');
    Log.d(TAG, 'Type password');

    var jid = xmpp.Jid.fromFullJid(this.jid);
    print(this.jid + '; jid:' + jid.local + '; domain:' + jid.domain + '; password:' + password + '; port:' + 5222.toString() + '; resource' + 'xmppstone');
    var account = xmpp.XmppAccountSettings(this.jid, jid.local, jid.domain, password, 5222); // , resource: 'xmppstone'
    _connection = xmpp.Connection(account);
    _connection.connect();

    return this;
  }

  void onReady() {
    _onReady(this);
  }

  void vCardRead() {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        Log.d(TAG, 'Your info' + vCard.buildXmlString());
      }
    });
  }

  void vCardUpdate(xmpp.VCard Function(xmpp.VCard vCardToUpdate) _onUpdate) {
    var vCardManager = xmpp.VCardManager(_connection);
    vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        Log.d(TAG, 'Your info' + vCard.buildXmlString());
      }
      // Update vcard information
      var _vCardUpdated = _onUpdate(vCard);
      Log.d(TAG, 'Updated info' + _vCardUpdated.buildXmlString());
      vCardManager.updateSelfVCard(_vCardUpdated).then((updatedAckVCard) {
        Log.d(TAG, 'Updated info success');
      });
    });
  }

  void readSessionLogs() {

  
    xmpp.MessagesListener messagesListener = ExampleMessagesListener();
    ConnectionManagerStateChangedListener(_connection, messagesListener, this);
    var presenceManager = xmpp.PresenceManager.getInstance(_connection);
    presenceManager.subscriptionStream.listen((streamEvent) {
      print(streamEvent.type.toString() + 'stream type');
      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
        Log.d(TAG, 'Accepting presence request');
        presenceManager.acceptSubscription(streamEvent.jid);
      }
    });
    var receiver = C_RECEIVER;
    var receiverJid = xmpp.Jid.fromFullJid(receiver);
    var messageHandler = xmpp.MessageHandler.getInstance(_connection);
    print(receiverJid.local + ', ' + receiverJid.domain);
    getConsoleStream().asBroadcastStream().listen((String str) {
      print('receive jid: ' + str);
      messageHandler.sendMessage(receiverJid, str);
    });
  }
}

// TODO: refactor
class ConnectionManagerStateChangedListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  xmpp.MessagesListener _messagesListener;
  XMPPClientManager _context;

  StreamSubscription<String> subscription;

  ConnectionManagerStateChangedListener(xmpp.Connection connection, xmpp.MessagesListener messagesListener, XMPPClientManager context) {
    _connection = connection;
    _messagesListener = messagesListener;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
    _context = context;
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      Log.d(TAG, 'Connected');
      // _context.vCardUpdate();
      // _context.vCardRead();
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

class ExampleMessagesListener implements xmpp.MessagesListener {
  @override
  void onNewMessage(xmpp.MessageStanza message) {
    if (message.body != null) {
      Log.d(TAG, format(
          'New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}'));
    }
  }
}
