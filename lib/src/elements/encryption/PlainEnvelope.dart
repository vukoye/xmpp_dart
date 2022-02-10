import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EnvelopeContent.dart';
import 'package:xmpp_stone/src/elements/encryption/EnvelopeFrom.dart';
import 'package:xmpp_stone/src/elements/encryption/EnvelopeRpad.dart';

class PlainEnvelope extends XmppElement {
  static String elementName = 'envelope';
  PlainEnvelope() {
    name = elementName;
  }

  PlainEnvelope.build(
      {required String xmlns,
      required String plainText,
      required String rpad,
      required Jid from}) {
    name = PlainEnvelope.elementName;
    addAttribute(XmppAttribute('xmlns', xmlns));
    addChild(EnvelopeContent.build(plainText: plainText));
    addChild(EnvelopeRpad.build(rpad: rpad));
    addChild(EnvelopeFrom.build(jid: from));
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PlainEnvelope.elementName),
        orElse: () => null);
  }
}
