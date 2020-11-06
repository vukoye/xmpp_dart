import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/StreamFeaturesElement.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class StreamFeaturesElementParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'stream:features';

  @override
  XmppElement parse(XmlElement xmlElement) {
    return StreamFeaturesElement();
  }

}