import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/messages/invitation/ReasonElement.dart';

class InviteElement extends XmppElement {
  static String elementName = 'invite';
  InviteElement() {
    name = elementName;
  }

  InviteElement.build(Jid to, String _reason) {
    name = elementName;
    addAttribute(XmppAttribute('to', to.fullJid));
    addChild(ReasonElement.build(_reason));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == InviteElement.elementName),
        orElse: () => null);
  }
}
