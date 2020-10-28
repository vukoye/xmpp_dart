import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class XElement extends XmppElement {
  XElement() {
    name = 'x';
  }

  XElement.build() {
    name = 'x';
    addAttribute(XmppAttribute('xmlns', 'jabber:x:data'));
  }

  void setType(FormType type) {
    addAttribute(XmppAttribute('type', type.toString().split('.').last.toLowerCase()));
  }

  void addField(FieldElement fieldElement) {
    addChild(fieldElement);
  }


}

enum FormType {
  FORM, SUBMIT, CANCEL, RESULT
}
