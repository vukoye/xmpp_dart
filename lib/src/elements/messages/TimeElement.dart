import 'package:xmpp_stone/src/elements/messages/TimeStampElement.dart';

import '../XmppAttribute.dart';
import '../XmppElement.dart';

class TimeElement extends XmppElement {
  static String elementName = 'TIME';
  TimeElement() {
    name = 'TIME';
  }

  TimeElement.build(value) {
    name = 'TIME';
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:time'));

    var tsElement = TimeStampElement();
    tsElement.textValue = value;
    addChild(tsElement);
  }

  void addField(TimeStampElement fieldElement) {
    addChild(fieldElement);
  }

  static XmppElement parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == TimeElement.elementName),
        orElse: () => XmppElement());
  }
}
