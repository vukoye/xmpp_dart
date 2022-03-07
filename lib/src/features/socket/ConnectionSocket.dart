import 'dart:async';
import 'dart:io';

import 'package:xmpp_stone/xmpp_stone.dart';

class ConnectionSocket {
  Socket? socket;
  ConnectionSocket(this.socket);

  static ConnectionSocket? instance;

  static void dispose() async {
    try {
      instance!.socket!.write('</stream:stream>');
      await instance!.socket!.flush();
      await instance!.socket!.close();
    } catch (e) {}
    if (instance != null) {
      instance!.socket = null;
    }
    instance = null;
  }

  static ConnectionSocket? hasInstance() {
    return instance;
  }

  static Future<ConnectionSocket> getInstance(
      XmppAccountSettings account) async {
    if (instance == null) {
      final socket =
          await Socket.connect(account.host ?? account.domain, account.port)
              .then((socket) => socket, onError: (error, stack) {
        Timer(const Duration(milliseconds: 200), () {
          ConnectionSocket.dispose();
        });
      });
      instance = ConnectionSocket(socket);
    }
    return instance!;
  }
}
