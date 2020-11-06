import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class PresenceStanzaParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) =>
      xmlElement.name.local == 'presence';

  @override
  XmppElement parse(XmlElement xmlElement) {
    var id = xmlElement.getAttribute('id');
    var stanza = PresenceStanza();
    stanza.id = id;
    return stanza;
  }
}
