import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Feature.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class FeatureElementParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'feature';

  @override
  XmppElement parse(XmlElement xmlElement) => Feature();

}