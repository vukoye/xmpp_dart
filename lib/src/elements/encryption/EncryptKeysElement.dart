import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeyElement.dart';

class EncryptKeysElement extends XmppElement {
  static String elementName = 'keys';
  EncryptKeysElement() {
    name = elementName;
  }

  EncryptKeysElement.build({
    required Jid to,
    required List<EncryptKeyElement> recipientKeys,
  }) {
    name = EncryptKeysElement.elementName;
    addAttribute(XmppAttribute('jid', to.userAtDomain));
    recipientKeys.forEach((recipientKey) {
      addChild(recipientKey);
    });
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EncryptKeysElement.elementName),
        orElse: () => null);
  }
}
