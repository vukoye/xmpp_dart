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

  void enablePush(
    String jid,
    String node, [
    Map<String, String> data = const {},
  ]) {
    final enableElement = XmppElement('enable')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:push:0'))
      ..addAttribute(XmppAttribute('jid', jid))
      ..addAttribute(XmppAttribute('node', node));
    if (data.isNotEmpty) {
      final xElement = XmppElement('x')
        ..addAttribute(XmppAttribute('xmlns', 'jabber:x:data'))
        ..addAttribute(XmppAttribute('type', 'submit'));
      data.forEach((key, value) {
        final fieldElement = XmppElement('field')
          ..addAttribute(XmppAttribute('var', key))
          ..addChild(XmppElement('value')..textValue = value);
        xElement.addChild(fieldElement);
      });
      enableElement.addChild(xElement);
    }
    final stanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..addChild(enableElement);
    _connection.writeStanza(stanza);
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
