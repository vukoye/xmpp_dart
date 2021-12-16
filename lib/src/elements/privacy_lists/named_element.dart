import '../XmppAttribute.dart';
import '../XmppElement.dart';

abstract class NamedElement extends XmppElement {
  void setName(String name) {
    addAttribute(XmppAttribute('name', '$name'));
  }
}
