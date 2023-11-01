import 'package:collection/collection.dart' show IterableExtension;
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

class MessageStanza extends AbstractStanza {
  final MessageStanzaType? type;

  MessageStanza(
    String? id, {
    this.type,
  }) : super('message') {
    this.id = id;
    addAttribute(
        XmppAttribute('type', type.toString().split('.').last.toLowerCase()));
  }

  String? get body => children
      .firstWhereOrNull(
          (child) => (child.name == 'body' && child.attributes.isEmpty))
      ?.textValue;

  set body(String? value) {
    var element = XmppElement('body');
    element.textValue = value;
    addChild(element);
  }

  String? get subject => children
      .firstWhereOrNull((child) => (child.name == 'subject'))
      ?.textValue;

  set subject(String? value) {
    var element = XmppElement('subject');
    element.textValue = value;
    addChild(element);
  }

  String? get thread =>
      children.firstWhereOrNull((child) => (child.name == 'thread'))?.textValue;

  set thread(String? value) {
    var element = XmppElement('thread');
    element.textValue = value;
    addChild(element);
  }
}

enum MessageStanzaType { CHAT, ERROR, GROUPCHAT, HEADLINE, NORMAL, UNKOWN }
