
import 'dart:math';

import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';

abstract class AbstractStanza extends XmppElement{
  String _id;
  Jid _fromJid;
  Jid _toJid;

  Jid get fromJid => _fromJid;

  set fromJid(Jid value) {
    _fromJid = value;
    this.addAttribute(new XmppAttribute('from', _fromJid.fullJid));
  }

  Jid get toJid => _toJid;

  set toJid(Jid value) {
    _toJid = value;
    this.addAttribute(new XmppAttribute('to', _toJid.userAtDomain));
  }

  String get id => _id;

  set id(String value) {
    _id = value;
    this.addAttribute(new XmppAttribute('id', _id));
  }

  static String getRandomId() {
    const ASCII_START = 65;
    const ASCII_END = 90;
    List<int> chars = new List(9);
    var codeUnits = new List.generate(9, (index) {
      return Random.secure().nextInt(ASCII_END - ASCII_START) + ASCII_START;
    });
    return String.fromCharCodes(codeUnits);
  }

}