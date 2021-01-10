import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class EnabledNonza extends Nonza {
  static String NAME = 'enabled';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(XmppElement nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  EnabledNonza() {
    name = NAME;
  }
}
