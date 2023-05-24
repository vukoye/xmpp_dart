import '../XmppElement.dart';
import 'named_element.dart';

class ListElement extends NamedElement {
  ListElement(String name) : super('list', name);

  void setItems(List<XmppElement> items) {
    items.forEach((element) {
      addChild(element);
    });
  }

  void addItem(XmppElement item) {
    addChild(item);
  }
}
