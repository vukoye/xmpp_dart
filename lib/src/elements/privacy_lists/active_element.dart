import 'named_element.dart';

class ActiveElement extends NamedElement {
  ActiveElement(String name) {
    this.name = 'active';
    setName(name);
  }
}
