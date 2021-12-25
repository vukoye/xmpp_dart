import '../XmppElement.dart';

class TimeStampElement extends XmppElement {
  static String elementName = 'ts';
  TimeStampElement() {
    name = elementName;
  }

  TimeStampElement.build(value) {
    name = elementName;
    textValue = value;
  }
  static XmppElement parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == TimeStampElement.elementName),
        orElse: () => XmppElement());
  }
}
