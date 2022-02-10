import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class BundleElement extends XmppElement {
  static String elementName = 'bundle';
  BundleElement() {
    name = elementName;
  }

  BundleElement.build(final String xmlns) {
    name = BundleElement.elementName;
    addAttribute(XmppAttribute('xmlns', xmlns));
  }

  BundleElement.buildOMEMOBundle() {
    name = BundleElement.elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:omemo:2'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == BundleElement.elementName),
        orElse: () => null);
  }
}
