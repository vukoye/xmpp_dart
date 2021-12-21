import '../XmppElement.dart';

class TimeStampElement extends XmppElement {
  TimeStampElement() {
    name = 'ts';
  }

  TimeStampElement.build(value) {
    name = 'ts';
    textValue = value;
  }
}
