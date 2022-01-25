import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ChatStateComposingElement extends XmppElement {
  static String elementName = 'composing';
  ChatStateComposingElement() {
    name = elementName;
  }

  ChatStateComposingElement.build() {
    name = elementName;
    addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ChatStateComposingElement.elementName),
        orElse: () => null);
  }
}
