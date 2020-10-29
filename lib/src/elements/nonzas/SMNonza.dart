import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class SMNonza extends Nonza {
  static String NAME = 'sm';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  SMNonza() {
    name = NAME;
  }
}
