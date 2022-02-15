import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class EncryptKeyElement extends XmppElement {
  static String elementName = 'key';
  EncryptKeyElement() {
    name = elementName;
  }

  EncryptKeyElement.build({
    required String rid,
    required bool keyExchange,
    required String encoded,
  }) {
    name = EncryptKeyElement.elementName;
    addAttribute(XmppAttribute('rid', rid));
    if (keyExchange) {
      addAttribute(XmppAttribute('kex', 'true'));
    }
    textValue = encoded;
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EncryptKeyElement.elementName),
        orElse: () => null);
  }
}
