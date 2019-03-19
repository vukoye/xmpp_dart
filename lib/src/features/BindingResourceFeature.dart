import 'dart:async';

import 'package:xmpp/src/Connection.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';
import 'package:xmpp/src/elements/nonzas/Nonza.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp/src/features/Feature.dart';
import 'package:xmpp/xmpp.dart';

class BindingResourceFeature extends Feature{
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;

  BindingResourceFeature(Connection connection) {
    _connection = connection;
  }
  @override
  bool match(Nonza request) {
    return request.name == "bind";
  }

  @override
  void negotiate(Nonza nonza) {
    if (nonza.name == "bind") {
      state = FeatureState.PARSING;
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
        state = FeatureState.DONE;
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