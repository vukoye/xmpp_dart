import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/rst/SetElement.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class SetElementParser extends XmppElementParser {

  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'set';

  @override
  XmppElement parse(XmlElement xmlElement) {
    return SetElement();
  }

  @override
  bool shouldParseAttributes() => true;

  @override
  bool shouldParseChildren() => true;

}