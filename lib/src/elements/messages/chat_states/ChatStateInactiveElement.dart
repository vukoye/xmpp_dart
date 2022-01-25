import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ChatStateInactiveElement extends XmppElement {
  static String elementName = 'inactive';
  ChatStateInactiveElement() {
    name = elementName;
  }

  ChatStateInactiveElement.build() {
    name = elementName;
    addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ChatStateInactiveElement.elementName),
        orElse: () => null);
  }
}
