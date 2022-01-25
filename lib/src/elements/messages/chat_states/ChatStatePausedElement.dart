import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ChatStatePausedElement extends XmppElement {
  static String elementName = 'paused';
  ChatStatePausedElement() {
    name = elementName;
  }

  ChatStatePausedElement.build() {
    name = elementName;
    addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ChatStatePausedElement.elementName),
        orElse: () => null);
  }
}
