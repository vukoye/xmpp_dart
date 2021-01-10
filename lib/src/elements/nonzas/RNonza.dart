import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class RNonza extends Nonza {
  static String NAME = 'r';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(XmppElement nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  RNonza() {
    name = NAME;
    addAttribute(XmppAttribute('xmlns', XMLNS));
  }
}
