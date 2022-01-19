import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ChatStateActiveElement extends XmppElement {
  static String elementName = 'active';
  ChatStateActiveElement() {
    name = elementName;
  }

  ChatStateActiveElement.build() {
    name = elementName;
    addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ChatStateActiveElement.elementName),
        orElse: () => null);
  }
}
