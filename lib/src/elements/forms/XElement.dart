import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class XElement extends XmppElement {
  static String elementName = 'x';
  XElement() {
    name = elementName;
  }

  XElement.build() {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'jabber:x:data'));
  }

  void setType(FormType type) {
    addAttribute(
        XmppAttribute('type', type.toString().split('.').last.toLowerCase()));
  }

  void addField(FieldElement fieldElement) {
    addChild(fieldElement);
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == XElement.elementName),
        orElse: () => null);
  }
}

enum FormType { FORM, SUBMIT, CANCEL, RESULT }
