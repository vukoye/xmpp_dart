import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/elements/encryption/PlainEnvelope.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/elements/messages/Amp.dart';
import 'package:xmpp_stone/src/elements/messages/AmpRuleElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomSubElement.dart';
import 'package:xmpp_stone/src/elements/messages/DelayElement.dart';
import 'package:xmpp_stone/src/elements/messages/ReceiptReceivedElement.dart';
import 'package:xmpp_stone/src/elements/messages/ReceiptRequestElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeStampElement.dart';
import 'package:xmpp_stone/src/elements/messages/carbon/ForwardedElement.dart';
import 'package:xmpp_stone/src/elements/messages/carbon/SentElement.dart';
import 'package:xmpp_stone/src/elements/messages/mam/ResultElement.dart';
import 'package:xmpp_stone/src/elements/messages/mam/StanzaIdElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Feature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Identity.dart';
import 'package:xmpp_stone/src/parser/IqParser.dart';

import '../elements/stanzas/MessageStanza.dart';
import '../logger/Log.dart';

class StanzaParser {
  static const TAG = 'StanzaParser';
  // '_' means any parents
  static final _elementMappings = <String, Function>{
    'query#identity': () => Identity(),
    'query#feature': () => Feature(),
    '_#x': () => XElement(),
    '_#field': () => FieldElement(),
    'message#time': () => TimeElement(),
    'time#ts': () => TimeStampElement(),
    'message#request': () => ReceiptRequestElement(),
    'message#received': () => ReceiptReceivedElement(),
    'message#amp': () => AmpElement(),
    'amp#rule': () => AmpRuleElement(),
    'message#custom': () => CustomElement(),
    'custom#custom': () => CustomSubElement(),
    // Delayed - offline storage
    'message#delay': () => DelayElement(),
    // Carbon feature
    'message#sent': () => SentElement(),
    // Message encrypt
    'message#envelope': () => PlainEnvelope(),
    'sent#forwarded': () => ForwardedElement(),
    // MAM
    'message#result': () => ResultElement(),
    'message#stanza-id': () => StanzaIdElement(),
    'result#forwarded': () => ForwardedElement(),
    'forwarded#delay': () => DelayElement(),
    'forwarded#message': () => MessageStanza('', MessageStanzaType.CHAT),
    'others': () => XmppElement(),
  };

  static AbstractStanza? parseMessageStanzaAttribute(
      AbstractStanza? stanza, xml.XmlElement element) {
    var fromString = element.getAttribute('from');
    if (fromString != null) {
      var from = Jid.fromFullJid(fromString);
      stanza!.fromJid = from;
    }
    var toString = element.getAttribute('to');
    if (toString != null) {
      var to = Jid.fromFullJid(toString);
      stanza!.toJid = to;
    }
    var idString = element.getAttribute('id');
    if (idString != null) {
      stanza!.id = idString;
    }
    // Look for message type if there are
    if (stanza is MessageStanza) {
      if (element.getAttribute('type') != null) {
        stanza.type = MessageStanzaType.values.lastWhere(
            (type) =>
                type.toString().toLowerCase() ==
                'MessageStanzaType.${(element.getAttribute('type')!)}'
                    .toLowerCase(),
            orElse: () => MessageStanzaType.UNKOWN);
      }
    }
    return stanza;
  }

  //TODO: Improve this!
  static AbstractStanza? parseStanza(xml.XmlElement element) {
    AbstractStanza? stanza;
    var id = element.getAttribute('id');
    if (id == null) {
      Log.d(TAG, 'No id found for stanza');
    }

    if (element.name.local == 'iq') {
      stanza = IqParser.parseIqStanza(id, element);
    } else if (element.name.local == 'message') {
      stanza = _parseMessageStanza(id, element);
    } else if (element.name.local == 'presence') {
      stanza = _parsePresenceStanza(id, element);
    }
    stanza = parseMessageStanzaAttribute(stanza, element);
    element.attributes.forEach((xmlAttribute) {
      stanza!.addAttribute(
          XmppAttribute(xmlAttribute.name.local, xmlAttribute.value));
    });
    element.children.forEach((child) {
      if (child is xml.XmlElement) stanza!.addChild(parseElement(child));
    });
    return stanza;
  }

  static MessageStanza _parseMessageStanza(String? id, xml.XmlElement element) {
    var typeString = element.getAttribute('type');
    MessageStanzaType? type;
    if (typeString == null) {
      type = MessageStanzaType.UNKOWN;
      Log.w(TAG, 'No type found for message stanza');
    } else {
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
    }
    var stanza = MessageStanza(id, type ?? MessageStanzaType.NONE);

    return stanza;
  }

  static PresenceStanza _parsePresenceStanza(
      String? id, xml.XmlElement element) {
    var presenceStanza = PresenceStanza();
    presenceStanza.id = id;
    return presenceStanza;
  }

  static XmppElement? parseElement(xml.XmlElement xmlElement) {
    XmppElement? xmppElement;
    var parentName = (xmlElement.parent as xml.XmlElement?)?.name.local ?? '';
    var name = xmlElement.name.local;
    final localKey = '$parentName#$name';
    final genericKey = '_#$name';
    var key = 'others';
    if (_elementMappings.containsKey(localKey)) {
      key = localKey;
    } else if (_elementMappings.containsKey(genericKey)) {
      key = genericKey;
    }
    xmppElement = _elementMappings[key]!();
    xmppElement!.name = xmlElement.name.local;

    if (xmppElement is MessageStanza) {
      xmppElement = parseMessageStanzaAttribute(xmppElement, xmlElement);
    }
    xmlElement.attributes.forEach((xmlAttribute) {
      xmppElement!.addAttribute(
          XmppAttribute(xmlAttribute.name.local, xmlAttribute.value));
    });
    xmlElement.children.forEach((xmlChild) {
      if (xmlChild is xml.XmlElement) {
        xmppElement!.addChild(parseElement(xmlChild));
      } else if (xmlChild is xml.XmlText) {
        xmppElement!.textValue = xmlChild.text;
      }
    });
    return xmppElement;
  }
}
