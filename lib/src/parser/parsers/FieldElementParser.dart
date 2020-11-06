import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Identity.dart';
import 'package:xmpp_stone/src/parser/CustomElementParsers.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class FieldElementParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'field';

  @override
  XmppElement parse(XmlElement xmlElement) => FieldElement();

}