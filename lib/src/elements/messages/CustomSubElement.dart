import '../XmppElement.dart';

class CustomSubElement extends XmppElement {
  static String elementName = 'custom';
  CustomSubElement() {
    name = 'custom';
  }

  CustomSubElement.build(value) {
    name = 'custom';
    textValue = value;
  }

  static XmppElement? parse(parent) {
    if (parent == null) {
      return null;
    }
    return parent.children.firstWhere(
        (child) => (child.name == CustomSubElement.elementName),
        orElse: () => null);
  }
}
