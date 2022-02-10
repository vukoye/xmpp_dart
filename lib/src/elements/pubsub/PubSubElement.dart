import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class PubSubElement extends XmppElement {
  static String elementName = 'pubsub';
  PubSubElement() {
    name = elementName;
  }

  PubSubElement.build() {
    name = PubSubElement.elementName;
    addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/pubsub'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PubSubElement.elementName),
        orElse: () => null);
  }
}
