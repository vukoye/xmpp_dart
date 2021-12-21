import '../XmppAttribute.dart';
import '../XmppElement.dart';

class ReceiptReceivedElement extends XmppElement {
  ReceiptReceivedElement() {
    name = 'received';
  }

  ReceiptReceivedElement.build() {
    name = 'received';
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:receipts'));
  }
}
