import '../XmppAttribute.dart';
import '../XmppElement.dart';

class AmpRuleElement extends XmppElement {
  static String elementName = 'rule';
  AmpRuleElement() {
    name = 'rule';
  }

  AmpRuleElement.build(String condition, String value, String action) {
    name = 'rule';
    addAttribute(XmppAttribute('condition', condition));
    addAttribute(XmppAttribute('value', value));
    addAttribute(XmppAttribute('action', action));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == AmpRuleElement.elementName),
        orElse: () => null);
  }
}
