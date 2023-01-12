import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class PushNotificationsManager {
  final Connection _connection;

  static final Map<Connection, PushNotificationsManager> _instances =
      <Connection, PushNotificationsManager>{};

  PushNotificationsManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  static PushNotificationsManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = PushNotificationsManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  void _connectionStateProcessor(XmppConnectionState event) {}

  void _processStanza(AbstractStanza? stanza) {}

  void enablePush(String jid, String node) {
    _connection
        .writeStanza(IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
          ..addChild(XmppElement('enable')
            ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:push:0'))
            ..addAttribute(XmppAttribute('jid', jid))
            ..addAttribute(XmppAttribute('node', node))));
  }

  void disablePush(String jid, String? node) {
    final disableElement = XmppElement('disable')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:push:0'))
      ..addAttribute(XmppAttribute('jid', jid));
    if (node != null && node.isNotEmpty) {
      disableElement.addAttribute(XmppAttribute('node', node));
    }
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..addChild(disableElement);
    _connection.writeStanza(iqStanza);
  }
}
