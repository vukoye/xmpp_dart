// Inspired by this XEP-0079: https://xmpp.org/extensions/xep-0079.html
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/features/servicediscovery/AmpNegotiator.dart';

enum AmpMessageType {
  None,
  Delivery,
}

class AmpManager {
  static Map<Connection, AmpManager> instances = <Connection, AmpManager>{};

  static AmpManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = AmpManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  final Connection _connection;

  AmpManager(this._connection);

  bool isReady() {
    return _connection.connectionNegotiationManager
        .isNegotiatorSupport((element) => element is AmpNegotiator);
  }
}
