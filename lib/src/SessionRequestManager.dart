import 'package:xmpp/src/StanzaListener.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/IqStanza.dart';

class SessionRequestManager implements StanzaProcessor {

  IqStanza sentRequest;

  SessionRequestManagerCallback _callback;
  SessionRequestManager(SessionRequestManagerCallback callback) {
    _callback = callback;
  }

  @override
  processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null && idValue == sentRequest?.getAttribute('id')?.value) {
        _callback.sessionReady();
      }
    }
  }

  AbstractStanza getSessionRequestStanza(String to) {
    IqStanza stanza = new IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    XmppElement sessionElement = new XmppElement();
    sessionElement.name = 'session';
    XmppAttribute attribute = new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-session');
    sessionElement.addAttribute(attribute);
    stanza.toJid = Jid("", to, "");
    stanza.addChild(sessionElement);
    sentRequest = stanza;
    return stanza;
  }
}

abstract class SessionRequestManagerCallback {
  void sessionReady();
}