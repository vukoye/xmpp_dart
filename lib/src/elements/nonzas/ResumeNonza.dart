import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class ResumeNonza extends Nonza {
  static String NAME = 'resume';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(Nonza nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  ResumeNonza(String id, int hValue) {
    name = NAME;
    addAttribute(XmppAttribute('xmlns', XMLNS));
    addAttribute(XmppAttribute('h', hValue.toString()));
    addAttribute(XmppAttribute('previd', id));
  }
}