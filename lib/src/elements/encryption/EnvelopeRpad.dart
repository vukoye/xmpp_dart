import 'package:xmpp_stone/src/elements/XmppElement.dart';

class EnvelopeRpad extends XmppElement {
  static String elementName = 'rpad';
  EnvelopeRpad() {
    name = elementName;
  }

  EnvelopeRpad.build({
    required String rpad,
  }) {
    name = EnvelopeRpad.elementName;
    textValue = rpad;
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EnvelopeRpad.elementName),
        orElse: () => null);
  }
}
