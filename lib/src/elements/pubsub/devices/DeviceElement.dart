import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class DeviceElement extends XmppElement {
  static String elementName = 'device';
  DeviceElement() {
    name = elementName;
  }

  DeviceElement.build({required String id, String label = ''}) {
    name = DeviceElement.elementName;

    addAttribute(XmppAttribute('id', id));
    if (label.isNotEmpty) {
      addAttribute(XmppAttribute('label', label));
    }
  }

  static List<XmppElement?> parse(XmppElement parent) {
    return parent.children
        .where((child) => (child!.name == DeviceElement.elementName))
        .toList();
  }
}
