import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptHeaderElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptPayloadElement.dart';

class EncryptElement extends XmppElement {
  static String elementName = 'encrypted';
  EncryptElement() {
    name = elementName;
  }

  EncryptElement.build({
    required EncryptHeaderElement header,
    required EncryptPayloadElement payload,
    required String encoded,
  }) {
    name = EncryptElement.elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:omemo:2'));
    addChild(header);
    addChild(payload);
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EncryptElement.elementName),
        orElse: () => null);
  }
}
