import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeElement.dart';

class EnvelopeContent extends XmppElement {
  static String elementName = 'content';
  EnvelopeContent() {
    name = elementName;
  }

  EnvelopeContent.build({
    required String plainText,
    String time = '',
    String customString = '',
  }) {
    name = EnvelopeContent.elementName;
    final body = XmppElement();
    body.name = 'body';

    body.addAttribute(XmppAttribute('xmlns', 'jabber:client'));
    body.textValue = plainText;

    if (time.isNotEmpty) {
      addChild(TimeElement.build(time));
    }
    if (customString.isNotEmpty) {
      addChild(CustomElement.build(customString));
    }
    addChild(body);
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EnvelopeContent.elementName),
        orElse: () => null);
  }
}
