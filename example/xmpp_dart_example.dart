import 'dart:convert';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:io';
import "package:console/console.dart";
import 'package:image/image.dart' as image;

main(List<String> arguments) {
  print("Type user@domain:");
  var userAtDomain = stdin.readLineSync(encoding: utf8);
  print("Type password");
  var password = stdin.readLineSync(encoding: utf8);
  print("Type port");
  int port;
  try {
    port = int.parse(stdin.readLineSync(encoding: utf8));
  } catch (e) {
    port = 5222;
  }
  xmpp.Jid jid = xmpp.Jid.fromFullJid(userAtDomain);
  xmpp.XmppAccount account = xmpp.XmppAccount(userAtDomain, jid.local, jid.domain, password, port);
  xmpp.Connection connection = new xmpp.Connection(account);
  connection.open();
  xmpp.MessagesListener messagesListener = ExampleMessagesListener();
  new ExampleConnectionStateChangedListener(connection, messagesListener);
  xmpp.PresenceManager presenceManager = xmpp.PresenceManager.getInstance(connection);
  presenceManager.subscriptionStream.listen((streamEvent) {
    if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
      print("Accepting presence request");
      presenceManager.acceptSubscription(streamEvent.jid);
    }
  });
}

class ExampleConnectionStateChangedListener implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  xmpp.MessagesListener _messagesListener;

  ExampleConnectionStateChangedListener(
      xmpp.Connection connection, xmpp.MessagesListener messagesListener) {
    _connection = connection;
    _messagesListener = messagesListener;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.DoneServiceDiscovery) {
      print("Connected");
      xmpp.VCardManager vCardManager = xmpp.VCardManager(_connection);
      vCardManager.getSelfVCard().then((vCard) {
        if (vCard != null) {
          print("Your info" + vCard.buildXmlString());
        }
      });
      xmpp.MessageHandler messageHandler =
          xmpp.MessageHandler.getInstance(_connection);
      messageHandler.messagesStream.listen(_messagesListener.onNewMessage);
      sleep(const Duration(seconds: 1));
      print("Enter receiver jid: ");
      var receiver = stdin.readLineSync(encoding: utf8);
      xmpp.Jid receiverJid = xmpp.Jid.fromFullJid(receiver);
      vCardManager.getVCardFor(receiverJid).then((vCard) {
        if (vCard != null) {
          print("Receiver info" + vCard.buildXmlString());
          if (vCard != null && vCard.image != null) {
            var file = new File('test456789.jpg')
              ..writeAsBytesSync(image.encodeJpg(vCard.image));
            print("IMAGE SAVED TO: ${file.path}");
          }
        }
      });
      print("write message text:");
      Console.adapter.byteStream().asBroadcastStream().map((bytes) {
        var str = ascii.decode(bytes);
        str = str.substring(0, str.length - 1);
        return str;
      }).listen((String str) {
        messageHandler.sendMessage(receiverJid, str);
      });
    }
  }
}

class ExampleMessagesListener implements xmpp.MessagesListener {
  @override
  onNewMessage(xmpp.MessageStanza message) {
    if (message.body != null) {
      print(format(
          "New Message from {color.blue}${message.fromJid.userAtDomain}{color.end} message: {color.red}${message.body}{color.end}"));
    }
  }
}
