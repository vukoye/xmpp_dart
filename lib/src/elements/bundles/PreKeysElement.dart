import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/bundles/PKElement.dart';

class PreKeysElement extends XmppElement {
  static String elementName = 'prekeys';
  PreKeysElement() {
    name = elementName;
  }

  PreKeysElement.build({required List<PKElement> pkElements}) {
    name = PreKeysElement.elementName;
    pkElements.forEach((element) {
      addChild(element);
    });
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PreKeysElement.elementName),
        orElse: () => null);
  }
}
