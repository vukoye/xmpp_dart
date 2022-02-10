import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class SPKElement extends XmppElement {
  static String elementName = 'spk';
  SPKElement() {
    name = elementName;
  }

  SPKElement.build({required String id, required String encodedData}) {
    name = SPKElement.elementName;
    addAttribute(XmppAttribute('id', id));
    textValue = encodedData;
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == SPKElement.elementName),
        orElse: () => null);
  }
}
