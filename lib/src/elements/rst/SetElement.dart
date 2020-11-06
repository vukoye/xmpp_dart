import 'package:xmpp_stone/src/elements/XmppAttribute.dart';

import '../XmppElement.dart';

class SetElement extends XmppElement {
  SetElement() {
    name = 'set';
  }

  SetElement.build({int max, String after, String before}) {
    name = 'set';
    addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/rsm'));
    if (max != null) {
      var maxElement = XmppElement();
      maxElement.textValue = max.toString();
      maxElement.name = 'max';
      addChild(maxElement);
    }
    if (after != null) {
      var afterElement = XmppElement();
      afterElement.textValue = after;
      afterElement.name = 'after';
      addChild(afterElement);
    }
    if (before != null) {
      var beforeElement = XmppElement();
      beforeElement.textValue = before;
      beforeElement.name = 'before';
      addChild(beforeElement);
    }
  }

  String get first => getChild('first')?.textValue;

  String get last => getChild('last')?.textValue;

  int get count {
    try {
      return int.parse(getChild('count')?.textValue);
    // ignore: empty_catches
    } catch (e) {}
    return null;
  }

  int get firstIndex {
    try {
      return int.parse(getChild('first')?.getAttribute('index')?.value);
      // ignore: empty_catches
    } catch (e) {}
    return null;
  }
}
