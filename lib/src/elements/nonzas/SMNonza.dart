import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class SMNonza extends Nonza {
  static String NAME = 'sm';
  static String XMLNS = 'urn:xmpp:sm:3';
  static String XMLNS_V2 = 'urn:xmpp:sm:2';

  static bool match(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns')!.value == XMLNS);

  static bool matchV2(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns')!.value == XMLNS_V2);

  SMNonza() {
    name = NAME;
  }
}
