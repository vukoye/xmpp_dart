import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class QueryElement extends XmppElement {
  QueryElement() : super('query');

  void addX(XElement xElement) {
    addChild(xElement);
  }

  void setXmlns(String xmlns) {
    addAttribute(XmppAttribute('xmlns', xmlns));
  }

  void setQueryId(String queryId) {
    addAttribute(XmppAttribute('queryid', queryId));
  }

  String? get queryId => getAttribute('queryid')?.value;
}
