import 'package:xmpp/xmpp.dart' as xmpp;
import 'dart:io';

main(List<String> arguments) {
  //testMe();

  xmpp.Connection connection = new xmpp.Connection("user@domain", "password", 5222);
  connection.open();
  MainConnectionStateChangedListener mainConnectionStateChangedListener = new MainConnectionStateChangedListener(connection);
  connection.addConnectionStateChangedListener(mainConnectionStateChangedListener);

}

class MainConnectionStateChangedListener implements xmpp.ConnectionStateChangedListener {

  xmpp.Connection _connection;
  MainConnectionStateChangedListener(xmpp.Connection connection) {
    _connection = connection;
  }
  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.SessionInitialized) {
      xmpp.MessageHandler messageHandler = xmpp.MessageHandler.getInstance(_connection);
      sleep(const Duration(seconds:1));
      messageHandler.sendMessage(xmpp.Jid.fromFullJid("user2@domain.com"), "hey");
    }
  }
}
