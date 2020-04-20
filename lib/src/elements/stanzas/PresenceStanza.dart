import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

class PresenceStanza extends AbstractStanza {
  PresenceStanza() {
    name = 'presence';
  }

  set type(PresenceType value) {
    String typeValue = value.toString().split('.').last.toLowerCase();
    _setAttributeValue('type', typeValue);
  }

  PresenceType get type {
    String typeValue = getAttribute('type')?.value;
    return typeFromString(typeValue);
  }

  set show(PresenceShowElement value) {
    String showValue = value.toString().split('.').last.toLowerCase();
    _setChildValue('show', showValue);
  }

  PresenceShowElement get show {
    String showValue = getChild('show')?.textValue;
    return showFromString(showValue);
  }

  //status with no language prefs
  String get status {
    var statusElement = children.firstWhere(
        (element) => element.name == name && element.attributes.isEmpty,
        orElse: () => null);
    return statusElement?.textValue;
  }

  set status(String value) {
    var childElement = children.firstWhere(
        (element) => element.name == 'status' && element.attributes.isEmpty,
        orElse: () => null);
    if (childElement == null) {
      var element = XmppElement();
      element.name = 'status';
      element.textValue = value;
      addChild(element);
    } else {
      childElement.textValue = value;
    }
  }

  int get priority {
    return int.tryParse(getChild('priority')?.textValue);
  }

  set priority(int value) {
    _setChildValue('priority', value.toString());
  }

  PresenceShowElement showFromString(String showString) {
    //AWAY, CHAT, DND, XA
    switch (showString) {
      case 'away':
        return PresenceShowElement.AWAY;
        break;
      case 'chat':
        return PresenceShowElement.CHAT;
        break;
      case 'dnd':
        return PresenceShowElement.DND;
        break;
      case 'xa':
        return PresenceShowElement.XA;
        break;
    }
    return null;
  }

  PresenceType typeFromString(String typeString) {
    switch (typeString) {
      case 'error':
        return PresenceType.ERROR;
        break;
      case 'probe':
        return PresenceType.PROBE;
        break;
      case 'subscribe':
        return PresenceType.SUBSCRIBE;
        break;
      case 'subscribed':
        return PresenceType.SUBSCRIBED;
        break;
      case 'unavailable':
        return PresenceType.UNAVAILABLE;
        break;
      case 'unsubscribe':
        return PresenceType.UNSUBSCRIBE;
        break;
      case 'unsubscribed':
        return PresenceType.UNSUBSCRIBED;
        break;
    }
    return null;
  }

  void _setChildValue(String childName, String value) {
    var childElement = children.firstWhere(
        (element) => element.name == childName && element.attributes.isEmpty,
        orElse: () => null);
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
    var attr = attributes.firstWhere((attribute) => attribute.name == name,
        orElse: () => null);
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
  UNSUBSCRIBED
}

enum PresenceShowElement { AWAY, CHAT, DND, XA }
