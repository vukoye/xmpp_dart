import 'dart:async';

import 'package:xmpp/src/Connection.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';
import 'package:xmpp/src/elements/nonzas/Nonza.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp/src/features/Feature.dart';
import 'package:xmpp/xmpp.dart';

class SessionInitiationFeature extends Feature{
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;

  IqStanza sentRequest;

  SessionInitiationFeature(Connection connection) {
    _connection = connection;
  }
  @override
  bool match(Nonza request) {
    return request.name == "session";
  }

  @override
  void negotiate(Nonza nonza) {
    if (nonza.name == "session") {
      state = FeatureState.PARSING;
      subscription = _connection.stanzasStream.listen(parseStanza);
      sendSessionInitiationStanza();
    }
  }

  void parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null && idValue == sentRequest?.getAttribute('id')?.value) {
        _connection.sessionReady();
        state = FeatureState.DONE;
      }
    }
  }

  void sendSessionInitiationStanza() {
    IqStanza stanza = new IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    XmppElement sessionElement = new XmppElement();
    sessionElement.name = 'session';
    XmppAttribute attribute = new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-session');
    sessionElement.addAttribute(attribute);
    stanza.toJid = Jid("", _connection.fullJid.domain, "");
    stanza.addChild(sessionElement);
    sentRequest = stanza;
    _connection.writeStanza(stanza);
  }

}