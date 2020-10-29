import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class EnabledNonza extends Nonza {
  static String NAME = 'enabled';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  EnabledNonza() {
    name = NAME;
  }
}
