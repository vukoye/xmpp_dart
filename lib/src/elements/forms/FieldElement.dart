


import '../XmppAttribute.dart';
import '../XmppElement.dart';

class FieldElement extends XmppElement {

  FieldElement() {
    name = 'field';
  }

  FieldElement.build({String varAttr, String typeAttr, String value}) {
    name = 'field';
    if (varAttr != null) {
      addAttribute(XmppAttribute('var', varAttr));
    }
    if (typeAttr != null) {
      addAttribute(XmppAttribute('type', typeAttr));
    }
    if (value != null) {
      var valueElement = XmppElement();
      valueElement.name = 'value';
      valueElement.textValue = value;
      addChild(valueElement);
    }
  }

  String get varAttr => getAttribute('var')?.value;

  String get typeAttr => getAttribute('type')?.value;

  String get value => getChild('value')?.textValue;
}