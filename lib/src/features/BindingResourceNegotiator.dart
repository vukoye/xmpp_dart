import 'dart:async';

import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/XmppElement.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/elements/stanzas/IqStanza.dart';
import 'package:xmppstone/src/features/Negotiator.dart';

class BindingResourceConnectionNegotiator extends ConnectionNegotiator{
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;

  BindingResourceConnectionNegotiator(Connection connection) {
    _connection = connection;
  }
  @override
  bool match(Nonza request) {
    return request.name == "bind";
  }

  @override
  void negotiate(Nonza nonza) {
    if (nonza.name == "bind") {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.stanzasStream.listen(parseStanza);
      sendBindRequestStanza();
    }
  }

  void parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      XmppElement element = stanza.getChild('bind');
      String jidValue = element?.getChild('jid')?.textValue;
      if (jidValue != null) {
        Jid jid = Jid.fromFullJid(jidValue);
        _connection.fullJidRetrieved(jid);
        state = NegotiatorState.DONE;
      }
    }
  }

  void sendBindRequestStanza() {
    IqStanza stanza = new IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    XmppElement bindElement = new XmppElement();
    bindElement.name = 'bind';
    XmppAttribute attribute = new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-bind');
    bindElement.addAttribute(attribute);
    stanza.addChild(bindElement);
    _connection.writeStanza(stanza);
  }

}