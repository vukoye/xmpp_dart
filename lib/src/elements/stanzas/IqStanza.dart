import 'package:xmpp_stone/src/elements/XmppAttribute.dart';

import 'AbstractStanza.dart';

class IqStanza extends AbstractStanza {
  IqStanzaType type = IqStanzaType.SET;

  IqStanza(String? id, IqStanzaType type) {
    name = 'iq';
    this.id = id;
    this.type = type;
    addAttribute(
        XmppAttribute('type', type.toString().split('.').last.toLowerCase()));
  }
}

enum IqStanzaType { ERROR, SET, RESULT, GET, INVALID, TIMEOUT }

class IqStanzaResult {
  IqStanzaType? type;
  String? description;
  String? iqStanzaId;
}
