import 'package:xmpp_stone/xmpp_stone.dart';

import '../../XmppAttribute.dart';
import '../../XmppElement.dart';

class ForwardedElement extends XmppElement {
  static String elementName = 'forwarded';
  ForwardedElement() {
    name = elementName;
  }

  ForwardedElement.build() {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:forward:0'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ForwardedElement.elementName),
        orElse: () => null);
  }

  static MessageStanza? parseForMessage(parent) {
    XmppElement? parentXmpp = parse(parent)!;
    if (parentXmpp != null) {
      return parentXmpp.children.firstWhere((child) => (child is MessageStanza),
          orElse: () => null) as MessageStanza;
    } else {
      return null;
    }
  }
}
