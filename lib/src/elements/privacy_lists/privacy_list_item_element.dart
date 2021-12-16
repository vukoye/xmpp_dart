import 'package:xml/xml.dart';

import '../XmppAttribute.dart';
import '../XmppElement.dart';
import '../../data/privacy_list_item.dart';
import '../../utils/string_utils.dart';

class PrivacyListItemElement extends XmppElement {
  late final PrivacyListItem item;

  PrivacyListItemElement({
    required this.item,
  }) {
    name = 'item';
  }

  PrivacyListItemElement.fromXml(XmppElement element) {
    name = element.name;

    var type = element.getAttribute('type')?.value?.toEnum(PrivacyType.values);
    var value = element.getAttribute('value')?.value;
    var action =
        element.getAttribute('action')!.value!.toEnum(PrivacyAction.values)!;
    var order = int.parse(element.getAttribute('order')?.value ?? '-1');

    var controlStanzas = <PrivacyControlStanza>[];

    element.children.forEach((element) {
      switch (element.name) {
        case 'message':
          controlStanzas.add(PrivacyControlStanza.MESSAGE);
          break;
        case 'iq':
          controlStanzas.add(PrivacyControlStanza.IQ);
          break;
        case 'presence-in':
          controlStanzas.add(PrivacyControlStanza.PRESENCE_IN);
          break;
        case 'presence-out':
          controlStanzas.add(PrivacyControlStanza.PRESENCE_OUT);
          break;
      }
    });

    item = PrivacyListItem(
        type: type,
        value: value,
        action: action,
        order: order,
        controlStanzas: controlStanzas);
  }

  @override
  XmlElement buildXml() {
    if (item.type != null) {
      addAttribute(XmppAttribute(
          'type', item.type.toString().split('.').last.toLowerCase()));
    }

    if (item.value != null) {
      addAttribute(XmppAttribute('value', item.value));
    }

    addAttribute(XmppAttribute(
        'action', item.action.toString().split('.').last.toLowerCase()));
    addAttribute(XmppAttribute('order', item.order.toString()));

    if (item.controlStanzas != null && item.controlStanzas!.isNotEmpty) {
      item.controlStanzas?.forEach((controlStanza) {
        addChild(XmppElement()
          ..name = controlStanza
              .toString()
              .split('.')
              .last
              .toLowerCase()
              .replaceAll('_', '-'));
      });
    }

    return super.buildXml();
  }
}
