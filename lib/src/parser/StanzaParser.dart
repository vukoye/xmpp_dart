import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
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

  //TODO: Improve this!
  static AbstractStanza parseStanza(xml.XmlElement element) {
    AbstractStanza stanza;
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
    var fromString = element.getAttribute('from');
    if (fromString != null) {
      var from = Jid.fromFullJid(fromString);
      stanza.fromJid = from;
    }
    var toString = element.getAttribute('to');
    if (toString != null) {
      var to = Jid.fromFullJid(toString);
      stanza.toJid = to;
    }
    element.attributes.forEach((xmlAttribute) {
      stanza.addAttribute(
          XmppAttribute(xmlAttribute.name.local, xmlAttribute.value));
    });
    element.children.forEach((child) {
      if (child is xml.XmlElement) stanza.addChild(parseElement(child));
    });
    return stanza;
  }

  static MessageStanza _parseMessageStanza(String id, xml.XmlElement element) {
    var typeString = element.getAttribute('type');
    MessageStanzaType type;
    if (typeString == null) {
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
    var stanza = MessageStanza(id, type);

    return stanza;
  }

  static PresenceStanza _parsePresenceStanza(
      String id, xml.XmlElement element) {
    var presenceStanza = PresenceStanza();
    presenceStanza.id = id;
    return presenceStanza;
  }

  static XmppElement parseElement(xml.XmlElement xmlElement) {
    XmppElement xmppElement;
    var parentName = (xmlElement.parent as xml.XmlElement)?.name?.local ?? '';
    var name = xmlElement?.name?.local;
    if (parentName == 'query' && name == 'identity') {
      xmppElement = Identity();
    } else if (parentName == 'query' && name == 'feature') {
      xmppElement = Feature();
    } else if (name == 'x') {
      xmppElement = XElement();
    } else if (name == 'field') {
      xmppElement = FieldElement();
    } else {
      xmppElement = XmppElement();
    }
    xmppElement.name = xmlElement?.name?.local;
    xmlElement.attributes.forEach((xmlAttribute) {
      xmppElement.addAttribute(
          XmppAttribute(xmlAttribute?.name?.local, xmlAttribute?.value));
    });
    xmlElement.children.forEach((xmlChild) {
      if (xmlChild is xml.XmlElement) {
        xmppElement.addChild(parseElement(xmlChild));
      } else if (xmlChild is xml.XmlText) {
        xmppElement.textValue = xmlChild.text;
      }
    });
    return xmppElement;
  }
}
