import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xml/xml.dart' as xml;

abstract class XmppElementParser {
  bool elementValidator(xml.XmlElement xmlElement);
  XmppElement parse(xml.XmlElement xmlElement);
  bool shouldParseChildren() => true;
  bool shouldParseAttributes() => true;
}