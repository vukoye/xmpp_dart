import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';

class PingManager {

  final Connection _connection;

  static Map<Connection, PingManager> instances = Map<Connection, PingManager>();

  PingManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  static getInstance(Connection connection) {
    PingManager manager = instances[connection];
    if (manager == null) {
      manager = PingManager(connection);
      instances[connection] = manager;
    }
    return manager;
  }

  void _connectionStateProcessor(XmppConnectionState event) {
    // connection state processor.
  }

  void _processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      if (stanza.type == IqStanzaType.GET) {
        var ping = stanza.getChild("ping");
        if (ping != null) {
          IqStanza iqStanza = IqStanza(stanza.id, IqStanzaType.RESULT);
          iqStanza.fromJid = _connection.fullJid;
          iqStanza.toJid = stanza.fromJid;
          _connection.writeStanza(iqStanza);
        }
      } else if (stanza.type == IqStanzaType.ERROR) {
        //todo handle error cases
      }
    }
  }
}
