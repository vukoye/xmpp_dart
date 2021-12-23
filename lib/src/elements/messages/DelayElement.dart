import '../XmppAttribute.dart';
import '../XmppElement.dart';

class DelayElement extends XmppElement {
  static String elementName = 'delay';
  DelayElement() {
    name = elementName;
  }

  DelayElement.build(String timestamp, String from) {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:delay'));
    addAttribute(XmppAttribute('stamp', timestamp));
    addAttribute(XmppAttribute('from', from));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == DelayElement.elementName),
        orElse: () => null);
  }
}
