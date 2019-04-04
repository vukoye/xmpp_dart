import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

class MessageStanza extends AbstractStanza {
  MessageStanzaType _type;

  MessageStanzaType get type => _type;

  set type(MessageStanzaType value) {
    _type = value;
  }

  MessageStanza(id, type) {
    name = 'message';
    this.id = id;
    _type = type;
    this.addAttribute(new XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }

  String get body => this.children.firstWhere((child) => (child.name == 'body' && child.attributes.isEmpty), orElse: () => null)?.textValue;


  set body(String value) {
    XmppElement element = XmppElement();
    element.name = 'body';
    element.textValue = value;
    this.addChild(element);
  }

  String get subject => this.children.firstWhere((child) => (child.name == 'subject'), orElse: () => null)?.textValue;

  set subject(String value) {
    XmppElement element = XmppElement();
    element.name = 'subject';
    element.textValue = value;
    this.addChild(element);
  }

  String get thread => this.children.firstWhere((child) => (child.name == 'thread'), orElse: () => null)?.textValue;

  set thread(String value) {
    XmppElement element = XmppElement();
    element.name = 'thread';
    element.textValue = value;
    this.addChild(element);
  }

}

enum MessageStanzaType {
  CHAT,
  ERROR,
  GROUPCHAT,
  HEADLINE,
  NORMAL
}