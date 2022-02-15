import 'package:xmpp_stone/src/elements/XmppElement.dart';

class EncryptPayloadElement extends XmppElement {
  static String elementName = 'payload';
  EncryptPayloadElement() {
    name = elementName;
  }

  EncryptPayloadElement.build({
    required String cipherText,
  }) {
    name = EncryptPayloadElement.elementName;
    textValue = cipherText;
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EncryptPayloadElement.elementName),
        orElse: () => null);
  }
}
