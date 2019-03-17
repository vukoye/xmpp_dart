import 'dart:convert';
import 'package:xmpp/xmpp.dart' as xmpp;
import 'dart:io';
import "package:console/console.dart";

main(List<String> arguments) {
  //testMe();
  print("Type user@domain:");
  var userAtDomain = stdin.readLineSync(encoding: utf8);
  print("Type password");
  var password = stdin.readLineSync(encoding: utf8);
  xmpp.Connection connection = new xmpp.Connection(userAtDomain, password, 5222);
  connection.open();
  xmpp.MessagesListener messagesListener = ExampleMessagesListener();
  ExampleConnectionStateChangedListener exampleConnectionStateChangedListener = new ExampleConnectionStateChangedListener(connection, messagesListener);
  connection.addConnectionStateChangedListener(exampleConnectionStateChangedListener);

}

class ExampleConnectionStateChangedListener implements xmpp.ConnectionStateChangedListener {

  xmpp.Connection _connection;
  xmpp.MessagesListener _messagesListener;
  ExampleConnectionStateChangedListener(xmpp.Connection connection, xmpp.MessagesListener messagesListener) {
    _connection = connection;
    _messagesListener = messagesListener;
  }
  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.SessionInitialized) {
      print("Connected");
      xmpp.MessageHandler messageHandler = xmpp.MessageHandler.getInstance(_connection);
      messageHandler.addMessagesListener(_messagesListener);
      sleep(const Duration(seconds:1));
      print("Enter receiver jid: ");
      var receiver = stdin.readLineSync(encoding: utf8);
      print("write message text (or exit if you want to exit");
      var shell = ShellPrompt();
      shell.loop().asyncMap((it) => it).listen((line) {
        if (["exit"].contains(line.toLowerCase().trim())) {
          shell.stop();
          return;
        }
        messageHandler.sendMessage(xmpp.Jid.fromFullJid(receiver), line);
      });
    }
  }
}

class ExampleMessagesListener implements xmpp.MessagesListener {
  @override
  onNewMessage(xmpp.MessageStanza message) {
   print("New Message from ${message.fromJid.userAtDomain} message: ${message.body}");
    return null;
  }

}
