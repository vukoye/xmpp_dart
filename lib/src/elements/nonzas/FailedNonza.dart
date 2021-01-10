import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class FailedNonza extends Nonza {
  static String NAME = 'failed';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(XmppElement nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  FailedNonza() {
    name = NAME;
  }
}
