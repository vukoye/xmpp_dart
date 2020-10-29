import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xml/xml.dart' as xml;

class XmppElement {
  String _name;
  String get name => _name;
  set name(String value) {
    _name = value;
  }

  String _textValue;
  String get textValue => _textValue;

  set textValue(String value) {
    _textValue = value;
  }

  final List<XmppElement> _children = <XmppElement>[];
  List<XmppElement> get children => _children;

  final List<XmppAttribute> _attributes = <XmppAttribute>[];
  XmppAttribute getAttribute(String name) {
    return _attributes.firstWhere((attr) => attr.name == name, orElse: () => null);
  }

  void addAttribute(XmppAttribute attribute) {
    var existing = getAttribute(attribute.name);
    if (existing != null) {
      _attributes.remove(existing);
    }
    _attributes.add(attribute);
  }

  void addChild(XmppElement element) {
    _children.add(element);
  }

  XmppElement getChild(String name) {
    return _children.firstWhere((element) => element.name == name, orElse: () => null);
  }

  String buildXmlString() {
    return buildXml().toXmlString(pretty: true);
  }

  xml.XmlElement buildXml() {
    var xmlAttributes = <xml.XmlAttribute>[];
    var xmlNodes = <xml.XmlNode>[];
    _attributes.forEach((xmppAttribute) {
      if (xmppAttribute.value != null) {
        xmlAttributes.add(xml.XmlAttribute(xml.XmlName(xmppAttribute.name), xmppAttribute.value));
      }
    });
    _children.forEach((xmppChild) {
      xmlNodes.add(xmppChild.buildXml());
    });
    if (textValue != null) {
      xmlNodes.add(xml.XmlText(textValue));
    }
    var xmlElement = xml.XmlElement(xml.XmlName(name), xmlAttributes, xmlNodes);
    return xmlElement;
  }

  String getNameSpace() {
    return getAttribute('xmlns')?.value;
  }

  List<XmppAttribute> get attributes => _attributes;
}
