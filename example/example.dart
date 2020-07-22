import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import 'package:console/console.dart';
import 'package:image/image.dart' as image;

void main(List<String> arguments) {
  print('Type user@domain:');
  //var userAtDomain = stdin.readLineSync(encoding: utf8);
  var userAtDomain = 'nemanja@127.0.0.1';

  ///var userAtDomain = 'a1@is-a-furry.org';
  ///
  print('Type password');
  var password = '1';
  //var password = stdin.readLineSync(encoding: utf8);
  //var password = '8027';
//  print('Type port');
//  int port;
//  try {
//    port = int.parse(stdin.readLineSync(encoding: utf8));
//  } catch (e) {
//    port = 5222;
//  }
  var jid = xmpp.Jid.fromFullJid(userAtDomain);
  var account = xmpp.XmppAccountSettings(userAtDomain, jid.local, jid.domain, password, 5222);
  var connection = xmpp.Connection(account);
  connection.connect();
  xmpp.MessagesListener messagesListener = ExampleMessagesListener();
  ExampleConnectionStateChangedListener(connection, messagesListener);
  xmpp.PresenceManager presenceManager = xmpp.PresenceManager.getInstance(connection);
  presenceManager.subscriptionStream.listen((streamEvent) {
    if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
      print('Accepting presence request');
      presenceManager.acceptSubscription(streamEvent.jid);
    }
  });
  var receiver = 'nemanja2@test';
  var receiverJid = xmpp.Jid.fromFullJid(receiver);
  xmpp.MessageHandler messageHandler = xmpp.MessageHandler.getInstance(connection);
  getConsoleStream().asBroadcastStream().listen((String str) {
    messageHandler.sendMessage(receiverJid, str);
  });
}

class ExampleConnectionStateChangedListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  xmpp.MessagesListener _messagesListener;

  StreamSubscription<String> subscription;

  ExampleConnectionStateChangedListener(xmpp.Connection connection, xmpp.MessagesListener messagesListener) {
    _connection = connection;
    _messagesListener = messagesListener;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      print('Connected');
      var vCardManager = xmpp.VCardManager(_connection);
      vCardManager.getSelfVCard().then((vCard) {
        if (vCard != null) {
          print('Your info' + vCard.buildXmlString());
        }
      });
      xmpp.MessageHandler messageHandler = xmpp.MessageHandler.getInstance(_connection);
      var rosterManager = xmpp.RosterManager.getInstance(_connection);
      messageHandler.messagesStream.listen(_messagesListener.onNewMessage);
      sleep(const Duration(seconds: 1));
      //print('Enter receiver jid: ');
      //var receiver = stdin.readLineSync(encoding: utf8);
      var receiver = 'nemanja2@test';
      var receiverJid = xmpp.Jid.fromFullJid(receiver);
      rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
        if (result.description != null) {
          print('add roster' + result.description);
        }
      });
      sleep(const Duration(seconds: 1));
      vCardManager.getVCardFor(receiverJid).then((vCard) {
        if (vCard != null) {
          print('Receiver info' + vCard.buildXmlString());
          if (vCard != null && vCard.image != null) {
            var file = File('test456789.jpg')..writeAsBytesSync(image.encodeJpg(vCard.image));
            print('IMAGE SAVED TO: ${file.path}');
          }
        }
      });
      xmpp.PresenceManager presenceManager = xmpp.PresenceManager.getInstance(_connection);
      presenceManager.presenceStream.listen(onPresence);
    }
  }

  void onPresence(xmpp.PresenceData event) {
    print('presence Event from ' + event.jid.fullJid + ' PRESENCE: ' + event.showElement.toString());
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
      print(format(
          'New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}'));
    }
  }
}
