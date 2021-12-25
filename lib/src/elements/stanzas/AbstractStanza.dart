import 'dart:math';

import 'package:xmpp_stone_obelisk/src/data/Jid.dart';
import 'package:xmpp_stone_obelisk/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone_obelisk/src/elements/XmppElement.dart';

abstract class AbstractStanza extends XmppElement {
  String? _id;
  Jid? _fromJid;
  Jid? _toJid;
  String? _status;

  Jid? get fromJid => _fromJid;

  set fromJid(Jid? value) {
    _fromJid = value;
    addAttribute(XmppAttribute('from', _fromJid!.fullJid));
  }

  Jid? get toJid => _toJid;

  set toJid(Jid? value) {
    _toJid = value;
    addAttribute(XmppAttribute('to', _toJid!.userAtDomain));
  }

  String? get id => _id;

  set id(String? value) {
    _id = value;
    addAttribute(XmppAttribute('id', _id));
  }

  set status(String? value) {
    _status = value;
  }

  String? get status => _status;

  static String getRandomId() {
    const ASCII_START = 65;
    const ASCII_END = 90;
    var codeUnits = List.generate(9, (index) {
      return Random.secure().nextInt(ASCII_END - ASCII_START) + ASCII_START;
    });
    return String.fromCharCodes(codeUnits);
  }
}
