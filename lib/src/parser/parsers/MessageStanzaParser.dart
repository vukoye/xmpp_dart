import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class MessageStanzaParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) =>
      xmlElement.name.local == 'message';

  @override
  XmppElement parse(XmlElement xmlElement) {
    var id = xmlElement.getAttribute('id');
    var messageStanza = MessageStanza(id, _parseMessageType(xmlElement));
    return messageStanza;
  }

  MessageStanzaType _parseMessageType(XmlElement xmlElement) {
    var typeString = xmlElement.getAttribute('type');
    MessageStanzaType type;
    switch (typeString) {
      case 'chat':
        type = MessageStanzaType.CHAT;
        break;
      case 'error':
        type = MessageStanzaType.ERROR;
        break;
      case 'groupchat':
        type = MessageStanzaType.GROUPCHAT;
        break;
      case 'headline':
        type = MessageStanzaType.HEADLINE;
        break;
      case 'normal':
        type = MessageStanzaType.NORMAL;
        break;
    }
    return type;
  }
}