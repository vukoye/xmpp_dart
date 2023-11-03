import 'package:xmpp_stone/xmpp_stone.dart';

class MucSubManager {
  static const xmlns = 'urn:xmpp:mucsub:0';

  static final Map<Connection, MucSubManager> _instances =
      <Connection, MucSubManager>{};

  final Connection _connection;

  MucSubManager(this._connection) {}

  static MucSubManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = MucSubManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  Future<void> subscribe(
    String toJid,
    List<MucSubEvents> events, {
    required String nick,
    String? password,
  }) async {
    final subscribeElement = XmppElement('subscribe')
      ..addAttribute(XmppAttribute('xmlns', xmlns))
      ..addAttribute(XmppAttribute('nick', nick));
    if (password != null) {
      subscribeElement.addAttribute(XmppAttribute('password', password));
    }
    events.forEach(
      (e) => subscribeElement.addChild(
        XmppElement('event')
          ..addAttribute(
            XmppAttribute('node', 'urn:xmpp:mucsub:nodes:${e.name}'),
          ),
      ),
    );
    final iqStanzaId = AbstractStanza.getRandomId();
    final iqStanza = IqStanza(iqStanzaId, IqStanzaType.SET)
      ..addAttribute(XmppAttribute('from', _connection.fullJid.fullJid))
      ..addAttribute(XmppAttribute('to', toJid))
      ..addChild(subscribeElement);
    _connection.writeStanza(iqStanza);
  }

  Future<void> unsubscribe(String toJid) async {
    final unsubscribeElement = XmppElement('unsubscribe')
      ..addAttribute(XmppAttribute('xmlns', xmlns));
    final iqStanzaId = AbstractStanza.getRandomId();
    final iqStanza = IqStanza(iqStanzaId, IqStanzaType.SET)
      ..addAttribute(XmppAttribute('from', _connection.fullJid.fullJid))
      ..addAttribute(XmppAttribute('to', toJid))
      ..addChild(unsubscribeElement);
    _connection.writeStanza(iqStanza);
  }

  Future<void> getSubscriptions(String toJid) async {
    final subscriptionsElement = XmppElement('subscriptions')
      ..addAttribute(XmppAttribute('xmlns', xmlns));
    final iqStanzaId = AbstractStanza.getRandomId();
    final iqStanza = IqStanza(iqStanzaId, IqStanzaType.GET)
      ..addAttribute(XmppAttribute('from', _connection.fullJid.fullJid))
      ..addAttribute(XmppAttribute('to', toJid))
      ..addChild(subscriptionsElement);
    _connection.writeStanza(iqStanza);
  }

//   <iq from='hag66@shakespeare.example'
//     to='coven@muc.shakespeare.example'
//     type='set'
//     id='E6E10350-76CF-40C6-B91B-1EA08C332FC7'>
//   <unsubscribe xmlns='urn:xmpp:mucsub:0' />
// </iq>

  /**
   * <iq from='hag66@shakespeare.example'
    to='coven@muc.shakespeare.example'
    type='set'
    id='E6E10350-76CF-40C6-B91B-1EA08C332FC7'>
  <subscribe xmlns='urn:xmpp:mucsub:0'
             nick='mynick'
             password='roompassword'>
    <event node='urn:xmpp:mucsub:nodes:messages' />
    <event node='urn:xmpp:mucsub:nodes:affiliations' />
    <event node='urn:xmpp:mucsub:nodes:subject' />
    <event node='urn:xmpp:mucsub:nodes:config' />
  </subscribe>
</iq>
   */
}

enum MucSubEvents {
  presence,
  messages,
  affiliations,
  subscribers,
  config,
  subject,
  system,
}

// urn:xmpp:mucsub:nodes:presence
// urn:xmpp:mucsub:nodes:messages
// urn:xmpp:mucsub:nodes:affiliations
// urn:xmpp:mucsub:nodes:subscribers
// urn:xmpp:mucsub:nodes:config
// urn:xmpp:mucsub:nodes:subject
// urn:xmpp:mucsub:nodes:system