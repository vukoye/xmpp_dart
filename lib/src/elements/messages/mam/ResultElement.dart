import '../../XmppAttribute.dart';
import '../../XmppElement.dart';

class ResultElement extends XmppElement {
  static String elementName = 'result';
  ResultElement() {
    name = elementName;
  }

  ResultElement.build(String queryId, String id) {
    name = elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:mam:2'));
    addAttribute(XmppAttribute('queryid', queryId));
    addAttribute(XmppAttribute('id', id));
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == ResultElement.elementName),
        orElse: () => null);
  }
}
