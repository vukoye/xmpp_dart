import 'package:xmpp_stone_obelisk/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone_obelisk/src/elements/XmppElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/Amp.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/AmpRuleElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/CustomSubElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/DelayElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/ReceiptReceivedElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/ReceiptRequestElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/TimeElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/TimeStampElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/messages/carbon/SentElement.dart';
import 'package:xmpp_stone_obelisk/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone_obelisk/src/extensions/advanced_messaging_processing/AmpInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_carbon/SentInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/CustomInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/DelayInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/ReceiptInterface.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/TimeInterface.dart';

class MessageStanza extends AbstractStanza
    implements
        ReceiptInterface,
        TimeInterface,
        AmpInterface,
        CustomInterface,
        DelayInterface,
        SentInterface {
  MessageStanzaType? _type;

  MessageStanzaType? get type => _type;

  set type(MessageStanzaType? value) {
    _type = value;
  }

  MessageStanza(id, type) {
    name = 'message';
    this.id = id;
    _type = type;
    addAttribute(
        XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }

  String? get body => children
      .firstWhere(
          (child) => (child!.name == 'body' && child.attributes.isEmpty),
          orElse: () => null)
      ?.textValue;

  set body(String? value) {
    var element = XmppElement();
    element.name = 'body';
    element.textValue = value;
    addChild(element);
  }

  String? get subject => children
      .firstWhere((child) => (child!.name == 'subject'), orElse: () => null)
      ?.textValue;

  set subject(String? value) {
    var element = XmppElement();
    element.name = 'subject';
    element.textValue = value;
    addChild(element);
  }

  String? get thread => children
      .firstWhere((child) => (child!.name == 'thread'), orElse: () => null)
      ?.textValue;

  set thread(String? value) {
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
  XmppElement? getRequestReceipt() {
    return ReceiptRequestElement.parse(this);
  }

  @override
  XmppElement? getReceivedReceipt() {
    return ReceiptReceivedElement.parse(this);
  }

  @override
  TimeInterface addTime(int? timeMilliseconds) {
    addChild(TimeElement.build(timeMilliseconds.toString()));
    return this;
  }

  @override
  XmppElement? getTime() {
    return TimeStampElement.parse(TimeElement.parse(this));
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
  XmppElement? getAmp() {
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
    return (amp.getAttribute('status')!.value == 'notify' &&
        rule!.getAttribute('condition')!.value == 'deliver' &&
        rule.getAttribute('value')!.value == 'direct');
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
    return (amp.getAttribute('status')!.value == 'notify' &&
        rule!.getAttribute('condition')!.value == 'deliver' &&
        rule.getAttribute('value')!.value == 'stored');
  }

  @override
  CustomInterface addCustom(String customString) {
    addChild(CustomElement.build(customString));
    return this;
  }

  @override
  XmppElement? getCustom() {
    return CustomSubElement.parse(CustomElement.parse(this));
  }

  @override
  XmppElement? getDelay() {
    return DelayElement.parse(this);
  }

  @override
  XmppElement? getSent() {
    return SentElement.parse(this);
  }
}

enum MessageStanzaType { CHAT, ERROR, GROUPCHAT, HEADLINE, NORMAL, UNKOWN }
