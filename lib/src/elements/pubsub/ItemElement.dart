import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ItemElement extends XmppElement {
  static String elementName = 'item';
  ItemElement() {
    name = elementName;
  }

  ItemElement.build(final String id) {
    name = ItemElement.elementName;

    addAttribute(XmppAttribute('id', id));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ItemElement.elementName),
        orElse: () => null);
  }
}
