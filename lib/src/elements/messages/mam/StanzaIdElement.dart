import '../../XmppAttribute.dart';
import '../../XmppElement.dart';

class StanzaIdElement extends XmppElement {
  static String elementName = 'stanza-id';
  StanzaIdElement() {
    name = elementName;
  }

  StanzaIdElement.build(String from, String stanzaArchiveId) {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:sid:0'));
    addAttribute(XmppAttribute('from', from));
    addAttribute(XmppAttribute('id', stanzaArchiveId));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == StanzaIdElement.elementName),
        orElse: () => null);
  }
}
