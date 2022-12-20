import '../XmppAttribute.dart';
import '../XmppElement.dart';

class FieldElement extends XmppElement {
  FieldElement() : super('field');

  FieldElement.build(
      {String /*?*/ varAttr, String /*?*/ typeAttr, String /*?*/ value})
      : super('field') {
    if (varAttr != null) {
      addAttribute(XmppAttribute('var', varAttr));
    }
    if (typeAttr != null) {
      addAttribute(XmppAttribute('type', typeAttr));
    }
    if (value != null) {
      var valueElement = XmppElement('value');
      valueElement.textValue = value;
      addChild(valueElement);
    }
  }

  String /*?*/ get varAttr => getAttribute('var')?.value;

  String /*?*/ get typeAttr => getAttribute('type')?.value;

  String /*?*/ get value => getChild('value')?.textValue;
}
