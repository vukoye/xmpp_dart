import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;

class Example{

static start() {
  print('XMPP STONE: Type user@domain:');
  var userAtDomain = 'jid@domain.com';
  print('XMPP STONE: Type password');
  var password = 'jidpassword';
  var jid = xmpp.Jid.fromFullJid(userAtDomain);
  var account = xmpp.XmppAccountSettings(userAtDomain, jid.local, jid.domain, password, 5222, resource: 'xmppstone', host: 'chatterboxtown.us');
  var connection = xmpp.Connection(account);
  connection.connect();
  xmpp.MessagesListener messagesListener = ExampleMessagesListener();
  ExampleConnectionStateChangedListener(connection, messagesListener);
  var presenceManager = xmpp.PresenceManager.getInstance(connection);
  presenceManager.subscriptionStream.listen((streamEvent) {
    if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
      print('XMPP STONE: Accepting presence request');
      presenceManager.acceptSubscription(streamEvent.jid);
    }
  });
  Future.delayed(const Duration(milliseconds: 5000), () {
  var receiver = 'jid2@domain.com';
  var receiverJid = xmpp.Jid.fromFullJid(receiver);
  var messageHandler = xmpp.MessageHandler.getInstance(connection);
  messageHandler.sendMessage(receiverJid, "hello there");
  });
}



}

class ExampleConnectionStateChangedListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection? _connection;
  late xmpp.MessagesListener _messagesListener;

  StreamSubscription<String>? subscription;

  ExampleConnectionStateChangedListener(xmpp.Connection connection, xmpp.MessagesListener messagesListener) {
    _connection = connection;
    _messagesListener = messagesListener;
    _connection!.connectionStateStream.listen(onConnectionStateChanged);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      print('XMPP STONE: Connected');
      var vCardManager = xmpp.VCardManager(_connection!);
      vCardManager.getSelfVCard().then((vCard) {
        if (vCard != null) {
          print('XMPP STONE: Your info' + vCard.buildXmlString());
        }
      });
      var messageHandler = xmpp.MessageHandler.getInstance(_connection!);
      var rosterManager = xmpp.RosterManager.getInstance(_connection!);
      messageHandler.messagesStream.listen(_messagesListener.onNewMessage);
      sleep(const Duration(seconds: 1));
      var receiver = 'nemanja2@test';
      var receiverJid = xmpp.Jid.fromFullJid(receiver);
      rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
        if (result.description != null) {
          print('XMPP STONE: add roster' + result.description!);
        }
      });
      sleep(const Duration(seconds: 1));
      vCardManager.getVCardFor(receiverJid).then((vCard) {
        if (vCard != null) {
          print('XMPP STONE: Receiver info' + vCard.buildXmlString());
          if (vCard != null && vCard.image != null) {
            var file = File('test456789.jpg')..writeAsBytesSync(image.encodeJpg(vCard.image!));
            print('XMPP STONE: IMAGE SAVED TO: ${file.path}');
          }
        }
      });
      var presenceManager = xmpp.PresenceManager.getInstance(_connection!);
      presenceManager.presenceStream.listen(onPresence);
    }
  }

  void onPresence(xmpp.PresenceData event) {
    print('XMPP STONE: presence Event from ' + event.jid!.fullJid! + ' PRESENCE: ' + event.showElement.toString());
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
  void onNewMessage(xmpp.MessageStanza? message) {
    if (message!.body != null) {
      print('New Message from {color.blue}${message.fromJid!.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}');
    }
  }
}
