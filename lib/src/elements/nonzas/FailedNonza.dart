import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

import '../stanzas/AbstractStanza.dart';

class FailedNonza extends Nonza {
  static String NAME = 'failed';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  FailedNonza() {
    name = NAME;
  }
}
