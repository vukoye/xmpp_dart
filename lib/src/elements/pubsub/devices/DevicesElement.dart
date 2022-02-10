import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DeviceElement.dart';

class DevicesElement extends XmppElement {
  static String elementName = 'devices';
  DevicesElement() {
    name = elementName;
  }

  DevicesElement.build(List<DeviceElement> devices) {
    name = DevicesElement.elementName;

    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:omemo:2'));
    devices.forEach((deviceElement) {
      addChild(deviceElement);
    });
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == DevicesElement.elementName),
        orElse: () => null);
  }
}
