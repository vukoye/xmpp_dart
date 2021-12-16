import 'named_element.dart';

class DefaultElement extends NamedElement {
  DefaultElement(String name) {
    this.name = 'default';
    setName(name);
  }
}