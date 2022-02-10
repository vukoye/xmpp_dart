import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/ping/PingListener.dart';

class OMEMOManager {
  final Connection _connection;

  PingListener? listener;

  static final Map<Connection, OMEMOManager> _instances =
      <Connection, OMEMOManager>{};

  OMEMOManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  static OMEMOManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = OMEMOManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  void _connectionStateProcessor(XmppConnectionState event) {
    // connection state processor.
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      if (stanza.type == IqStanzaType.GET) {
        var ping = stanza.getChild('ping');
        if (ping != null) {
          var iqStanza = IqStanza(stanza.id, IqStanzaType.RESULT);
          iqStanza.fromJid = _connection.fullJid;
          iqStanza.toJid = stanza.fromJid;
          _connection.writeStanza(iqStanza);

          if (listener != null) {
            listener!.onPing(stanza);
          }
        }
      } else if (stanza.type == IqStanzaType.ERROR) {
        //todo handle error cases
      }
    }
  }

  void listen(PingListener _listener) {
    if (listener != null) {
      listener = null;
    }
    listener = _listener;
  }
}
