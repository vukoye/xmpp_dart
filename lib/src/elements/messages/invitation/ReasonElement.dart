import 'package:xmpp_stone/src/elements/XmppElement.dart';

class ReasonElement extends XmppElement {
  static String elementName = 'reason';
  ReasonElement() {
    name = elementName;
  }

  ReasonElement.build(String _reason) {
    name = elementName;
    textValue = _reason;
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ReasonElement.elementName),
        orElse: () => null);
  }
}
