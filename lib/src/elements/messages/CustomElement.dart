import 'package:xmpp_stone/src/elements/messages/CustomSubElement.dart';

import '../XmppAttribute.dart';
import '../XmppElement.dart';

class CustomElement extends XmppElement {
  static String elementName = 'CUSTOM';
  CustomElement() {
    name = elementName;
  }

  CustomElement.build(value) {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:custom'));
    addChild(CustomSubElement.build(value));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == CustomElement.elementName),
        orElse: () => null);
  }
}
