import '../XmppElement.dart';

class CustomSubElement extends XmppElement {
  CustomSubElement() {
    name = 'custom';
  }

  CustomSubElement.build(value) {
    name = 'custom';
    textValue = value;
  }
}
