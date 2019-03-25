import 'package:xmppstone/src/Connection.dart';

abstract class ConnectionStateChangedListener {
  void onConnectionStateChanged(XmppConnectionState state);
}