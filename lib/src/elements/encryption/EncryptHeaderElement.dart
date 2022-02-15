import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeysElement.dart';

class EncryptHeaderElement extends XmppElement {
  static String elementName = 'header';
  EncryptHeaderElement() {
    name = elementName;
  }

  EncryptHeaderElement.build({
    required String senderDeviceId,
    required List<EncryptKeysElement> recipientKeysList,
  }) {
    name = EncryptHeaderElement.elementName;
    addAttribute(XmppAttribute('sid', senderDeviceId));
    recipientKeysList.forEach((recipientKey) {
      addChild(recipientKey);
    });
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EncryptHeaderElement.elementName),
        orElse: () => null);
  }
}
