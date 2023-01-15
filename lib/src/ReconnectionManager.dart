import 'dart:async';
import 'dart:math';
import 'package:xmpp_stone/src/Connection.dart';
import 'logger/Log.dart';

class ReconnectionManager {
  static const TAG = 'ReconnectionManager';

  Connection _connection;
  bool isActive = false;
  int initialTimeout = 1000;
  int maxTimeout = -1;
  int totalReconnections = 3;
  int timeOutInMs;
  int counter = 0;
  Timer? timer;

  ReconnectionManager(Connection connection)
      : this._connection = connection,
        timeOutInMs = connection.account.reconnectionTimeout {
    _connection.connectionStateStream.listen(connectionStateHandler);
    initialTimeout = _connection.account.reconnectionTimeout;
    maxTimeout = _connection.account.maxReconnectionTimeout;
    totalReconnections = _connection.account.totalReconnections;
  }

  void connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.ForcefullyClosed) {
      Log.d(TAG, 'Connection forcefully closed!'); //connection lost
      handleReconnection();
    } else if (state == XmppConnectionState.SocketOpening) {
      //do nothing
    } else if (state != XmppConnectionState.Reconnecting) {
      isActive = false;
      timeOutInMs = initialTimeout;
      counter = 0;
      if (timer != null) {
        timer!.cancel();
        timer = null;
      }
    }
  }

  void handleReconnection() {
    if (timer != null) {
      timer!.cancel();
    }
    if (totalReconnections == -1 || counter < totalReconnections) {
      timer = Timer(Duration(milliseconds: timeOutInMs), _connection.reconnect);
      if (maxTimeout == -1) {
        timeOutInMs *= 2;
      } else {
        timeOutInMs = min(timeOutInMs * 2, maxTimeout);
      }
      Log.d(TAG, 'TimeOut is: $timeOutInMs reconnection counter $counter');
      counter++;
    } else {
      _connection.close();
    }
  }
}
