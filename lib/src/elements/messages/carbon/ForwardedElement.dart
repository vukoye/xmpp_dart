import '../../XmppAttribute.dart';
import '../../XmppElement.dart';

class ForwardedElement extends XmppElement {
  static String elementName = 'forwarded';
  ForwardedElement() {
    name = elementName;
  }

  ForwardedElement.build(String timestamp, String from) {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:forward:0'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ForwardedElement.elementName),
        orElse: () => null);
  }
}
