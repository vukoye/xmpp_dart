import 'package:xmpp_stone/src/elements/XmppElement.dart';

class SPKSElement extends XmppElement {
  static String elementName = 'spks';
  SPKSElement() {
    name = elementName;
  }

  SPKSElement.build({required String encodedData}) {
    name = SPKSElement.elementName;
    textValue = encodedData;
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == SPKSElement.elementName),
        orElse: () => null);
  }
}
