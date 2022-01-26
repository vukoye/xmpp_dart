import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/last_activity/LastActivityApi.dart';

// Implementation of standard: https://xmpp.org/extensions/xep-0012.html
const iqLastActivityXmlns = 'jabber:iq:last';

class LastActivityManager implements LastActivityApi {
  final Connection _connection;

  final Map<String?, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String?, Tuple2<IqStanza, Completer>>{};

  static final Map<Connection, LastActivityManager> _instances =
      <Connection, LastActivityManager>{};

  LastActivityManager(this._connection) {
    _connection.inStanzasStream.listen(_processStanza);
  }

  static LastActivityManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = LastActivityManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  @override
  Future<String> askLastActivity(Jid to) {
    var completer = Completer<String>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = to;
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', iqLastActivityXmlns));
    iqStanza.addChild(queryElement);

    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza &&
        stanza.type == IqStanzaType.RESULT &&
        _myUnrespondedIqStanzas.containsKey(stanza.id)) {
      var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];

      if (_myUnrespondedIqStanzas[stanza.id] != null) {
        final queryElement = stanza.getChild('query');
        if (queryElement != null &&
            queryElement.getAttribute('xmlns')!.value == iqLastActivityXmlns) {
          final lastActivitySeconds =
              queryElement.getAttribute('seconds')!.value;
          unrespondedStanza!.item2.complete(lastActivitySeconds);
        }
      } else if (stanza.type == IqStanzaType.ERROR) {
        unrespondedStanza!.item2.complete(-1);
      }
    }
  }
}
