import 'dart:async';

import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/last_activity/LastActivityApi.dart';
import 'package:xmpp_stone/src/extensions/last_activity/LastActivityData.dart';
import 'package:xmpp_stone/src/response/base_response.dart';
import 'package:xmpp_stone/src/response/response.dart';

// Implementation of standard: https://xmpp.org/extensions/xep-0012.html
const iqLastActivityXmlns = 'jabber:iq:last';

class LastActivityManager implements LastActivityApi {
  final Connection _connection;

  static final ResponseHandler<IqStanza> responseHandler =
      ResponseHandler<IqStanza>();

  static final Map<Connection, LastActivityManager> _instances =
      <Connection, LastActivityManager>{};

  LastActivityManager(this._connection) {
    _connection.inStanzasStream
        .where((AbstractStanza? stanza) =>
            stanza != null && responseHandler.keys().contains(stanza.id ?? ""))
        .listen(_processStanza);
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
  Future<LastActivityResponse> askLastActivity(Jid to) {
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = to;
    final queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', iqLastActivityXmlns));
    iqStanza.addChild(queryElement);

    _connection.writeStanza(iqStanza);

    return responseHandler.set<LastActivityResponse>(iqStanza.id!, iqStanza,
        description: 'Ask for user last activity');
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      responseHandler.test(stanza.id!, (res) {
        late BaseResponse response;
        switch (res.item3) {
          case LastActivityResponse:
            response = LastActivityResponse.parse(stanza);
            break;
        }
        res.item2.complete(response);
      });
    }
  }
}
