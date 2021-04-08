import 'package:collection/collection.dart' show IterableExtension;
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

class PresenceStanza extends AbstractStanza {
  PresenceStanza() {
    name = 'presence';
  }

  PresenceStanza.withType(PresenceType type) {
    name = 'presence';
    addAttribute(XmppAttribute('type', type.toString().split('.').last.toLowerCase()));
  }

  set type(PresenceType? value) {
    var typeValue = value.toString().split('.').last.toLowerCase();
    _setAttributeValue('type', typeValue);
  }

  PresenceType? get type {
    var typeValue = getAttribute('type')?.value;
    return typeFromString(typeValue);
  }

  set show(PresenceShowElement? value) {
    var showValue = value.toString().split('.').last.toLowerCase();
    _setChildValue('show', showValue);
  }

  PresenceShowElement? get show {
    var showValue = getChild('show')?.textValue;
    return showFromString(showValue);
  }

  //status with no language prefs
  String? get status {
    var statusElement =
        children.firstWhereOrNull((element) => element.name == 'status' && element.attributes.isEmpty);
    return statusElement?.textValue;
  }

  set status(String? value) {
    var childElement =
        children.firstWhereOrNull((element) => element.name == 'status' && element.attributes.isEmpty);
    if (childElement == null) {
      var element = XmppElement();
      element.name = 'status';
      element.textValue = value;
      addChild(element);
    } else {
      childElement.textValue = value;
    }
  }

  int? get priority {
    var priority = getChild('priority');

    return priority == null || priority.textValue == null ? null : int.tryParse(priority.textValue!);
  }

  set priority(int? value) {
    _setChildValue('priority', value.toString());
  }

  PresenceShowElement? showFromString(String? showString) {
    //AWAY, CHAT, DND, XA
    switch (showString) {
      case 'away':
        return PresenceShowElement.AWAY;
      case 'chat':
        return PresenceShowElement.CHAT;
      case 'dnd':
        return PresenceShowElement.DND;
      case 'xa':
        return PresenceShowElement.XA;
    }

    return null;
  }

  PresenceType? typeFromString(String? typeString) {
    switch (typeString) {
      case 'error':
        return PresenceType.ERROR;
      case 'probe':
        return PresenceType.PROBE;
      case 'subscribe':
        return PresenceType.SUBSCRIBE;
      case 'subscribed':
        return PresenceType.SUBSCRIBED;
      case 'unavailable':
        return PresenceType.UNAVAILABLE;
      case 'unsubscribe':
        return PresenceType.UNSUBSCRIBE;
      case 'unsubscribed':
        return PresenceType.UNSUBSCRIBED;
    }

    return null;
  }

  void _setChildValue(String childName, String value) {
    var childElement =
        children.firstWhereOrNull((element) => element.name == childName && element.attributes.isEmpty);
    if (childElement == null) {
      var element = XmppElement();
      element.name = childName;
      element.textValue = value;
      addChild(element);
    } else {
      childElement.textValue = value;
    }
  }

  void _setAttributeValue(String attrName, String value) {
    var attr = attributes.firstWhereOrNull((attribute) => attribute.name == name);
    if (attr == null) {
      var element = XmppElement();
      element.name = attrName;
      element.textValue = value;
      addChild(element);
    } else {
      attr.value = value;
    }
  }
}

enum PresenceType {
  ERROR,
  PROBE,
  SUBSCRIBE,
  SUBSCRIBED,
  UNAVAILABLE,
  UNSUBSCRIBE,
  UNSUBSCRIBED,
}

enum PresenceShowElement {
  AWAY,
  CHAT,
  DND,
  XA,
}
