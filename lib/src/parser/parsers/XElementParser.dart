import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class XELementParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'x';

  @override
  XmppElement parse(XmlElement xmlElement) => XElement();

}