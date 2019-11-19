import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

class SessionInitiationNegotiator extends ConnectionNegotiator{
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;

  IqStanza sentRequest;

  SessionInitiationNegotiator(Connection connection) {
    _connection = connection;
  }
  @override
  bool match(Nonza request) {
    return request.name == "session";
  }

  @override
  void negotiate(Nonza nonza) {
    if (nonza.name == "session") {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(parseStanza);
      sendSessionInitiationStanza();
    }
  }

  void parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null && idValue == sentRequest?.getAttribute('id')?.value) {
        _connection.sessionReady();
        state = NegotiatorState.DONE;
      }
    }
  }

  void sendSessionInitiationStanza() {
    IqStanza stanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    XmppElement sessionElement = XmppElement();
    sessionElement.name = 'session';
    XmppAttribute attribute = XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-session');
    sessionElement.addAttribute(attribute);
    stanza.toJid = Jid("", _connection.fullJid.domain, "");
    stanza.addChild(sessionElement);
    sentRequest = stanza;
    _connection.writeStanza(stanza);
  }

}