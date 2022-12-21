import 'package:xmpp_stone/src/elements/XmppAttribute.dart';

import 'AbstractStanza.dart';

class IqStanza extends AbstractStanza {
  IqStanzaType _type = IqStanzaType.SET;

  IqStanzaType get type => _type;

  String _id;

  @override
  String get id => _id;

  set type(IqStanzaType value) {
    _type = value;
  }

  IqStanza(String id, IqStanzaType type) : _id = id, _type = type, super('iq') {
    this.id = id;
    addAttribute(
        XmppAttribute('type', _type.toString().split('.').last.toLowerCase()));
  }
}

enum IqStanzaType { ERROR, SET, RESULT, GET, INVALID, TIMEOUT }

class IqStanzaResult {
  late IqStanzaType type;
  String description = '';
  String? iqStanzaId;
}
