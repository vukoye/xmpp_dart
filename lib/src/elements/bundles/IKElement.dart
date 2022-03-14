import 'package:xmpp_stone/src/elements/XmppElement.dart';

class IKElement extends XmppElement {
  static String elementName = 'ik';
  IKElement() {
    name = elementName;
  }

  IKElement.build({required String encodedData}) {
    name = IKElement.elementName;
    textValue = encodedData;
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == IKElement.elementName),
        orElse: () => null);
  }
}
