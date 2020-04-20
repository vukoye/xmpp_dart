import 'package:xmpp_stone/src/elements/XmppAttribute.dart';

import 'AbstractStanza.dart';

class IqStanza extends AbstractStanza {
  IqStanzaType _type = IqStanzaType.SET;

  IqStanzaType get type => _type;

  set type(IqStanzaType value) {
    _type = value;
  }

  IqStanza(String id, IqStanzaType type) {
    name = 'iq';
    this.id = id;
    _type = type;
    this.addAttribute(
        XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }

//  String buildXml() {
//    //todo (maybe in AbstractStanza)
//
//    var attributeType = xml.XmlAttribute(xml.XmlName('type'), _type.toString().split('.').last.toLowerCase());
//    var attributeId = xml.XmlAttribute(xml.XmlName('id'), this.id);
//    var listOfAttributes = [attributeId, attributeType];
//    if (fromJid != null) {
//      var attr = xml.XmlAttribute(xml.XmlName('from'), fromJid.fullJid);
//      listOfAttributes.add(attr);
//    }
//    if (toJid != null) {
//      var attr = xml.XmlAttribute(xml.XmlName('to'), toJid.domain);
//      listOfAttributes.add(attr);
//    }
//    var stanza = xml.XmlElement(xml.XmlName('iq'), listOfAttributes);
//    //stanza.children.add(_content);
//    return stanza.toXmlString();
//  }
}

enum IqStanzaType { ERROR, SET, RESULT, GET, INVALID, TIMEOUT }

class IqStanzaResult {
  IqStanzaType type;
  String description;
  String iqStanzaId;
}
