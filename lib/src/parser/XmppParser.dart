import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/features/rsm/SetElementParser.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/parser/parsers/FeatureElementParser.dart';
import 'package:xmpp_stone/src/parser/parsers/FieldElementParser.dart';
import 'package:xmpp_stone/src/parser/parsers/IdentityElementParser.dart';
import 'package:xmpp_stone/src/parser/parsers/IqStanzaParser.dart';
import 'package:xmpp_stone/src/parser/parsers/MessageStanzaParser.dart';
import 'package:xmpp_stone/src/parser/parsers/PresenceStanzaParser.dart';
import 'package:xmpp_stone/src/parser/parsers/StreamElementParser.dart';
import 'package:xmpp_stone/src/parser/parsers/StreamFeaturesElementParser.dart';
import 'package:xmpp_stone/src/parser/parsers/XElementParser.dart';

class XmppParser {
  XmppParser();

  final List<XmppElementParser> _defaultParsers = [
    MessageStanzaParser(),
    IqStanzaParser(),
    PresenceStanzaParser(),
    StreamElementParser(),
    SetElementParser(),
    FeatureElementParser(),
    FieldElementParser(),
    IdentityElementParser(),
    XELementParser(),
    StreamFeaturesElementParser()
  ];
  final List<XmppElementParser> _customParsers = [];

  void addCustomParser(XmppElementParser parser) {
    _customParsers.add(parser);
  }

  XmppElement parse(xml.XmlElement xmlElement) {
    var parser = _customParsers.firstWhere(
        (parser) => parser.elementValidator(xmlElement),
        orElse: () => null);
    parser ??= _defaultParsers.firstWhere(
        (parser) => parser.elementValidator(xmlElement),
        orElse: () => null);
    XmppElement xmppElement;
    if (parser != null) {
      xmppElement = parser.parse(xmlElement);
    } else {
      xmppElement = XmppElement();
      xmppElement.name = xmlElement?.name?.local;
    }
    if (parser == null || parser.shouldParseAttributes()) {
      xmlElement.attributes.forEach((xmlAttribute) {
        xmppElement.addAttribute(
            XmppAttribute(xmlAttribute?.name?.local, xmlAttribute?.value));
      });
    }
    if (parser == null || parser.shouldParseChildren()) {
      xmlElement.children.forEach((xmlChild) {
        if (xmlChild is xml.XmlElement) {
          xmppElement.addChild(parse(xmlChild));
        } else if (xmlChild is xml.XmlText) {
          xmppElement.textValue = xmlChild.text;
        }
      });
    }
    return xmppElement;
  }
}
