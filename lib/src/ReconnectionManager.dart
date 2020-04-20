
import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';

class ReconnectionManager {
  Connection _connection;
  bool isActive = false;
  static const int INITIAL_TIMEOUT = 1000;
  static const int TOTAL_RECONNECTING = 5;
  int timeOutInMs = INITIAL_TIMEOUT;
  int counter = 0;
  Timer timer;

  ReconnectionManager(Connection connection) {
    _connection = connection;
    _connection.connectionStateStream.listen(connectionStateHandler);
  }

  void connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.ForcelyClosed) {
      print("Connection forcely closed!"); //connection lost
      handleReconnection();
    } else if (state == XmppConnectionState.SocketOpening) {
      //do nothing
    }else if (state != XmppConnectionState.Reconnecting) {
      isActive = false;
      timeOutInMs = INITIAL_TIMEOUT;
      counter = 0;
      if (timer != null) {
        timer.cancel();
        timer = null;
      }
    }
  }

  void handleReconnection() {
    if (timer != null) {
      timer.cancel();
    }
    if (counter< TOTAL_RECONNECTING) {
      timer = Timer(Duration(milliseconds: timeOutInMs), _connection.reconnect);
      timeOutInMs += timeOutInMs;
      print("TimeOut is:" + timeOutInMs.toString() + "recconection counter" + counter.toString());
      counter++;
    } else {
      _connection.close();
    }
  }
}