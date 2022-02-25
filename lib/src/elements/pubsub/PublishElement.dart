import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class PublishElement extends XmppElement {
  static String elementName = 'publish';
  PublishElement() {
    name = elementName;
  }

  PublishElement.build(final String node) {
    name = PublishElement.elementName;
    addAttribute(XmppAttribute('node', node));
  }

  PublishElement.buildOMEMODevice() {
    name = PublishElement.elementName;
    addAttribute(XmppAttribute('node', 'urn:xmpp:omemo:2:devices'));
  }
  PublishElement.buildOMEMOBundle() {
    name = PublishElement.elementName;
    addAttribute(XmppAttribute('node', 'urn:xmpp:omemo:2:bundles'));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PublishElement.elementName),
        orElse: () => null);
  }
}
