import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

import '../elements/nonzas/Nonza.dart';

class SessionInitiationNegotiator extends Negotiator {
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;

  IqStanza sentRequest;

  SessionInitiationNegotiator(Connection connection) {
    _connection = connection;
    expectedName = 'SessionInitiationNegotiator';
  }
  @override
  List<Nonza> match(List<Nonza> requests) {
    var nonza = requests.firstWhere((request) => request.name == 'session', orElse: () => null);
    return nonza != null ? [nonza] : [];
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    if (match(nonzas).isNotEmpty) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(parseStanza);
      sendSessionInitiationStanza();
    }
  }

  void parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null &&
          idValue == sentRequest?.getAttribute('id')?.value) {
        _connection.sessionReady();
        state = NegotiatorState.DONE;
      }
    }
  }

  void sendSessionInitiationStanza() {
    var stanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var sessionElement = XmppElement();
    sessionElement.name = 'session';
    var attribute =
        XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-session');
    sessionElement.addAttribute(attribute);
    stanza.toJid = _connection.serverName;
    stanza.addChild(sessionElement);
    sentRequest = stanza;
    _connection.writeStanza(stanza);
  }
}
