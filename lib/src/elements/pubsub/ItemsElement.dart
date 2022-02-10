import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ItemsElement extends XmppElement {
  static String elementName = 'items';
  ItemsElement() {
    name = elementName;
  }

  ItemsElement.build(final String node) {
    name = ItemsElement.elementName;

    addAttribute(XmppAttribute('node', node));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ItemsElement.elementName),
        orElse: () => null);
  }
}
