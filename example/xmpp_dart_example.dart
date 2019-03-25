import 'dart:convert';
import 'package:xmppstone/xmppstone.dart' as xmpp;
import 'dart:io';
import "package:console/console.dart";

main(List<String> arguments) {
  print("Type user@domain:");
  var userAtDomain = stdin.readLineSync(encoding: utf8);
  print("Type password");
  var password = stdin.readLineSync(encoding: utf8);
  xmpp.Connection connection = new xmpp.Connection(userAtDomain, password, 5222);
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
      xmpp.MessageHandler messageHandler =
          xmpp.MessageHandler.getInstance(_connection);
      messageHandler.messagesStream.listen(_messagesListener.onNewMessage);
      sleep(const Duration(seconds: 1));
      print("Enter receiver jid: ");
      var receiver = stdin.readLineSync(encoding: utf8);
      print("write message text:");
      Console.adapter.byteStream().asBroadcastStream().map((bytes) {
        var str = ascii.decode(bytes);
        str = str.substring(0, str.length - 1);
        return str;
      }).listen((String str) {
        messageHandler.sendMessage(xmpp.Jid.fromFullJid(receiver), str);
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
