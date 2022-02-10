import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class EnvelopeContent extends XmppElement {
  static String elementName = 'content';
  EnvelopeContent() {
    name = elementName;
  }

  EnvelopeContent.build({
    required String plainText,
  }) {
    name = EnvelopeContent.elementName;
    final body = XmppElement();
    body.name = 'body';

    body.addAttribute(XmppAttribute('xmlns', 'jabber:client'));
    body.textValue = plainText;
    addChild(body);
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EnvelopeContent.elementName),
        orElse: () => null);
  }
}
