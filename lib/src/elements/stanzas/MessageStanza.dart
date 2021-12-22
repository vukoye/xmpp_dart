import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/messages/Amp.dart';
import 'package:xmpp_stone/src/elements/messages/AmpRuleElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone/src/elements/messages/ReceiptReceivedElement.dart';
import 'package:xmpp_stone/src/elements/messages/ReceiptRequestElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/extensions/advanced_messaging_processing/AmpInterface.dart';

abstract class ReceiptInterface {
  ReceiptInterface addRequestReceipt();
  ReceiptInterface addReceivedReceipt();
  String getReceipt();
}

abstract class TimeInterface {
  ReceiptInterface addTime(int timeMilliseconds);
  XmppElement getTime();
}

abstract class CustomInterface {
  ReceiptInterface addCustom(String customString);
  XmppElement getCustom();
}

class MessageStanza extends AbstractStanza
    implements ReceiptInterface, TimeInterface, AmpInterface, CustomInterface {
  MessageStanzaType _type;

  MessageStanzaType get type => _type;

  set type(MessageStanzaType value) {
    _type = value;
  }

  MessageStanza(id, type) {
    name = 'message';
    this.id = id;
    _type = type;
    addAttribute(
        XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }

  String get body => children
      .firstWhere((child) => (child.name == 'body' && child.attributes.isEmpty),
          orElse: () => null)
      ?.textValue;

  set body(String value) {
    var element = XmppElement();
    element.name = 'body';
    element.textValue = value;
    addChild(element);
  }

  String get subject => children
      .firstWhere((child) => (child.name == 'subject'), orElse: () => null)
      ?.textValue;

  set subject(String value) {
    var element = XmppElement();
    element.name = 'subject';
    element.textValue = value;
    addChild(element);
  }

  String get thread => children
      .firstWhere((child) => (child.name == 'thread'), orElse: () => null)
      ?.textValue;

  set thread(String value) {
    var element = XmppElement();
    element.name = 'thread';
    element.textValue = value;
    addChild(element);
  }

  @override
  ReceiptInterface addReceivedReceipt() {
    addChild(ReceiptReceivedElement.build());
    return this;
  }

  @override
  ReceiptInterface addRequestReceipt() {
    addChild(ReceiptRequestElement.build());
    return this;
  }

  @override
  String getReceipt() {
    return children
        .firstWhere(
            (child) => (child.name == 'request' || child.name == 'received'),
            orElse: () => null)
        ?.textValue;
  }

  @override
  ReceiptInterface addTime(int timeMilliseconds) {
    addChild(TimeElement.build(timeMilliseconds.toString()));
    return this;
  }

  @override
  XmppElement getTime() {
    return TimeElement.parse(this);
  }

  @override
  AmpInterface addAmpDeliverDirect() {
    addChild(AmpElement.build([
      AmpRuleElement.build('deliver', 'direct', 'notify'),
      AmpRuleElement.build('deliver', 'stored', 'notify')
    ]));
    return this;
  }

  @override
  XmppElement getAmp() {
    return AmpElement.parse(this);
  }

  @override
  bool isAmpDeliverDirect() {
    var amp = AmpElement.parse(this);
    if (amp == null) {
      return false;
    }
    var rule = AmpRuleElement.parse(AmpElement.parse(this));
    if (amp == rule) {
      return false;
    }
    return (amp.getAttribute('status').value == 'notify' &&
        rule.getAttribute('condition').value == 'deliver' &&
        rule.getAttribute('value').value == 'direct');
  }

  @override
  bool isAmpDeliverStore() {
    var amp = AmpElement.parse(this);
    if (amp == null) {
      return false;
    }
    var rule = AmpRuleElement.parse(AmpElement.parse(this));
    if (amp == rule) {
      return false;
    }
    return (amp.getAttribute('status').value == 'notify' &&
        rule.getAttribute('condition').value == 'deliver' &&
        rule.getAttribute('value').value == 'stored');
  }

  @override
  ReceiptInterface addCustom(String customString) {
    addChild(CustomElement.build(customString));
    return this;
  }

  @override
  XmppElement getCustom() {
    return CustomElement.parse(this);
  }
}

enum MessageStanzaType { CHAT, ERROR, GROUPCHAT, HEADLINE, NORMAL, UNKOWN }
enum ReceiptRequestType { NONE, REQUEST, RECEIVED }
