import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class PKElement extends XmppElement {
  static String elementName = 'pk';
  PKElement() {
    name = elementName;
  }

  PKElement.build({required String id, required String encodedData}) {
    name = PKElement.elementName;
    addAttribute(XmppAttribute('id', id));
    textValue = encodedData;
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PKElement.elementName),
        orElse: () => null);
  }
}
