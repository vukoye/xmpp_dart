import '../XmppAttribute.dart';
import '../XmppElement.dart';

abstract class NamedElement extends XmppElement {
  NamedElement(super.name, String nameAttribute) {
    addAttribute(XmppAttribute('name', nameAttribute));
  }
}
