import 'dart:math';

import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

abstract class AbstractStanza extends XmppElement {
  String _id;

  Jid get fromJid => Jid.fromFullJid(getAttribute('from')?.value);

  set fromJid(Jid value) {
    addAttribute(XmppAttribute('from', value.fullJid));
  }

  Jid get toJid => Jid.fromFullJid(getAttribute('to')?.value);

  set toJid(Jid value) {
    addAttribute(XmppAttribute('to', value.userAtDomain));
  }

  String get id => _id;

  set id(String value) {
    _id = value;
    addAttribute(XmppAttribute('id', _id));
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
