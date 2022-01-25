import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ChatStateGoneElement extends XmppElement {
  static String elementName = 'gone';
  ChatStateGoneElement() {
    name = elementName;
  }

  ChatStateGoneElement.build() {
    name = elementName;
    addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ChatStateGoneElement.elementName),
        orElse: () => null);
  }
}
