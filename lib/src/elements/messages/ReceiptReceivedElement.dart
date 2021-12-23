import '../XmppAttribute.dart';
import '../XmppElement.dart';

class ReceiptReceivedElement extends XmppElement {
  static String elementName = 'received';
  ReceiptReceivedElement() {
    name = elementName;
  }

  ReceiptReceivedElement.build() {
    name = ReceiptReceivedElement.elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:receipts'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ReceiptReceivedElement.elementName),
        orElse: () => null);
  }
}
