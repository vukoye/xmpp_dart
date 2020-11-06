import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/StreamElement.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class StreamElementParser  extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'stream';

  @override
  XmppElement parse(XmlElement xmlElement) {
    return StreamElement();
  }
}