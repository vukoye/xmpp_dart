import 'dart:math';

import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

abstract class AbstractStanza extends XmppElement {
  String /*?*/ _id;
  Jid /*?*/ _fromJid;
  Jid /*?*/ _toJid;

  Jid get fromJid => _fromJid;

  AbstractStanza(String name) : super(name);

  set fromJid(Jid /*?*/ value) {
    _fromJid = value;
    if (value == null) {
      removeAttribute('from');
    } else {
      addAttribute(XmppAttribute('from', value.fullJid));
    }
  }

  Jid /*?*/ get toJid => _toJid;

  set toJid(Jid /*?*/ value) {
    _toJid = value;
    if (value == null) {
      removeAttribute('to');
    } else {
      addAttribute(XmppAttribute('to', value.userAtDomain));
    }
  }

  String /*?*/ get id => _id;

  set id(String /*?*/ value) {
    _id = value;
    if (value == null) {
      removeAttribute('id');
    } else {
      addAttribute(XmppAttribute('id', value));
    }
  }

  static String getRandomId() {
    const ASCII_START = 65;
    const ASCII_END = 90;
    var codeUnits = List.generate(9, (index) {
      return Random.secure().nextInt(ASCII_END - ASCII_START) + ASCII_START;
    });
    return String.fromCharCodes(codeUnits);
  }
}
