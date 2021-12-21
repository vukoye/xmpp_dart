import '../XmppAttribute.dart';
import '../XmppElement.dart';

class ReceiptRequestElement extends XmppElement {
  ReceiptRequestElement() {
    name = 'request';
  }

  ReceiptRequestElement.build() {
    name = 'request';
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:receipts'));
  }
}
