import 'package:collection/collection.dart' show IterableExtension;
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xml/xml.dart' as xml;

class XmppElement {
  final String name;
  String? textValue;

  final List<XmppElement> _children = <XmppElement>[];
  List<XmppElement> get children => _children;

  final List<XmppAttribute> _attributes = <XmppAttribute>[];

  XmppElement(this.name);

  XmppAttribute? getAttribute(String? name) {
    return _attributes.firstWhereOrNull((attr) => attr.name == name);
  }

  void addAttribute(XmppAttribute attribute) {
    removeAttribute(attribute.name);
    _attributes.add(attribute);
  }

  void removeAttribute(String name) {
    var existing = getAttribute(name);
    if (existing != null) {
      _attributes.remove(existing);
    }
  }

  void addChild(XmppElement element) {
    _children.add(element);
  }

  bool removeChild(XmppElement element) {
    return _children.remove(element);
  }

  XmppElement? getChild(String name) {
    return _children.firstWhereOrNull((element) => element.name == name);
  }

  String buildXmlString() {
    return buildXml().toXmlString(pretty: false);
  }

  xml.XmlElement buildXml() {
    var xmlAttributes = <xml.XmlAttribute>[];
    var xmlNodes = <xml.XmlNode>[];
    _attributes.forEach((xmppAttribute) {
      if (xmppAttribute.value != null) {
        xmlAttributes.add(xml.XmlAttribute(
            xml.XmlName(xmppAttribute.name), xmppAttribute.value!));
      }
    });
    _children.forEach((xmppChild) {
      xmlNodes.add(xmppChild.buildXml());
    });
    if (textValue != null) {
      xmlNodes.add(xml.XmlText(textValue!));
    }
    var xmlElement = xml.XmlElement(xml.XmlName(name), xmlAttributes, xmlNodes);
    return xmlElement;
  }

  String? getNameSpace() {
    return getAttribute('xmlns')?.value;
  }

  List<XmppAttribute> get attributes => _attributes;
}
