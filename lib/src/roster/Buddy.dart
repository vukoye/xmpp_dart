
import 'package:xmpp/src/data/Jid.dart';

class Buddy {
  Jid _jid;

  Jid get jid => _jid;

  Buddy(Jid jid) {
    _jid = jid;
  }

  String toString() {
    return _jid.fullJid;
  }
}