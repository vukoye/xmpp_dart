import '../XmppAttribute.dart';
import '../XmppElement.dart';
import './AmpRuleElement.dart';

class AmpElement extends XmppElement {
  static String elementName = 'amp';
  AmpElement() {
    name = 'amp';
  }

  AmpElement.build(List<AmpRuleElement> rules) {
    name = 'amp';
    addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/amp'));

    rules.forEach((rule) {
      addChild(rule);
    });
  }

  void addField(AmpRuleElement ruleElement) {
    addChild(ruleElement);
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == AmpElement.elementName),
        orElse: () => null);
  }
}
