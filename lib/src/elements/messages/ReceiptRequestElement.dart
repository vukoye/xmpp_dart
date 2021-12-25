import '../XmppAttribute.dart';
import '../XmppElement.dart';

class ReceiptRequestElement extends XmppElement {
  static String elementName = 'request';
  ReceiptRequestElement() {
    name = 'request';
  }

  ReceiptRequestElement.build() {
    name = 'request';
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:receipts'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ReceiptRequestElement.elementName),
        orElse: () => null);
  }
}
