import 'package:xmpp_stone/src/elements/forms/XElement.dart';

import '../../../xmpp_stone.dart';
import '../XmppAttribute.dart';
import '../XmppElement.dart';

class QueryElement extends XmppElement{
  QueryElement() {
    name = 'query';
  }

  void addX(XElement xElement) {
    addChild(xElement);
  }

  void setXmlns(String xmlns) {
    addAttribute(XmppAttribute('xmlns', xmlns));
  }

  void setQueryid(String queryId) {
    XmppAttribute('queryid', queryId);
  }

  String get queryId => getAttribute('queryid')?.value;
}