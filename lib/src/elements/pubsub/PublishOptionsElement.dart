import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';

class PublishOptionsElement extends XmppElement {
  static String elementName = 'publish-options';
  PublishOptionsElement() {
    name = elementName;
  }

  PublishOptionsElement.build({String maxItems = '', String accessModel = ''}) {
    name = PublishOptionsElement.elementName;
    final xElement = XElement.build();
    xElement.setType(FormType.SUBMIT);
    final fieldFormType = FieldElement.build(
        varAttr: 'FORM_TYPE',
        typeAttr: 'hidden',
        value: 'http://jabber.org/protocol/pubsub#publish-options');
    xElement.addChild(fieldFormType);
    if (accessModel.isNotEmpty) {
      final fieldAccessModel = FieldElement.build(
          varAttr: 'pubsub#access_model', value: accessModel);
      xElement.addChild(fieldAccessModel);
    }
    if (maxItems.isNotEmpty) {
      final fieldMaxItem =
          FieldElement.build(varAttr: 'pubsub#max_items', value: maxItems);
      xElement.addChild(fieldMaxItem);
    }
    addChild(xElement);
  }

  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == PublishOptionsElement.elementName),
        orElse: () => null);
  }
}
