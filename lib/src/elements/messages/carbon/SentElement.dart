import '../../XmppAttribute.dart';
import '../../XmppElement.dart';

class SentElement extends XmppElement {
  static String elementName = 'sent';
  SentElement() {
    name = elementName;
  }

  SentElement.build() {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:carbons:2'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == SentElement.elementName),
        orElse: () => null);
  }
}
