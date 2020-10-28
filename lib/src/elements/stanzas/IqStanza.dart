import 'package:xmpp_stone/src/elements/XmppAttribute.dart';

import 'AbstractStanza.dart';

class IqStanza extends AbstractStanza {
  IqStanzaType _type = IqStanzaType.SET;

  IqStanzaType get type => _type;

  set type(IqStanzaType value) {
    _type = value;
  }

  IqStanza(String id, IqStanzaType type) {
    name = 'iq';
    this.id = id;
    _type = type;
    addAttribute(
        XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }
}

enum IqStanzaType { ERROR, SET, RESULT, GET, INVALID, TIMEOUT }

class IqStanzaResult {
  IqStanzaType type;
  String description;
  String iqStanzaId;
}
