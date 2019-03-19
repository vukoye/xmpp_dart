
import 'package:xmpp/src/StanzaListener.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp/xmpp.dart';

class BindingResourceManager implements StanzaProcessor {

  BindingResourceCallBack _callback;
  BindingResourceManager(BindingResourceCallBack callback) {
    _callback = callback;
  }

  void processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      XmppElement element = stanza.getChild('bind');
      String jidValue = element?.getChild('jid')?.textValue;
      if (jidValue != null) {
        Jid jid = Jid.fromFullJid(jidValue);
        _callback?.fullJidRetrieved(jid);
      }
    }
  }

  AbstractStanza getBindRequestStanza() {
    IqStanza stanza = new IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    XmppElement bindElement = new XmppElement();
    bindElement.name = 'bind';
    XmppAttribute attribute = new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-bind');
    bindElement.addAttribute(attribute);
    stanza.addChild(bindElement);
    return stanza;
  }
}

abstract class BindingResourceCallBack {
   void fullJidRetrieved(Jid jid);
}



