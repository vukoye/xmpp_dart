import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xml/xml.dart' as xml;

class Nonza extends XmppElement {
  Nonza(String name) : super(name);

  Jid? _fromJid;
  Jid? _toJid;

  Jid? get fromJid => _fromJid;

  set fromJid(Jid? value) {
    _fromJid = value;
    if (value == null) {
      removeAttribute('from');
    } else {
      addAttribute(XmppAttribute('from', value.fullJid));
    }
  }

  Jid? get toJid => _toJid;

  set toJid(Jid? value) {
    _toJid = value;
    if (value == null) {
      removeAttribute('to');
    } else {
      addAttribute(XmppAttribute('to', value.userAtDomain));
    }
  }

  static Nonza parse(xml.XmlElement xmlElement) {
    var nonza = Nonza(xmlElement.name.local);

    var fromString = xmlElement.getAttribute('from');
    if (fromString != null) {
      var from = Jid.fromFullJid(fromString);
      nonza.fromJid = from;
    }
    var toString = xmlElement.getAttribute('to');
    if (toString != null) {
      var to = Jid.fromFullJid(toString);
      nonza.toJid = to;
    }
    xmlElement.attributes.forEach((attribute) => nonza
        .addAttribute(XmppAttribute(attribute.name.local, attribute.value)));
    xmlElement.children.forEach((xmlChild) {
      if (xmlChild is xml.XmlElement) {
        nonza.addChild(StanzaParser.parseElement(xmlChild));
      } else if (xmlChild is xml.XmlText) {
        nonza.textValue = xmlChild.text;
      }
    });
    return nonza;
  }
}
