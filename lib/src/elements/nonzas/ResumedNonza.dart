import 'package:xmpp_stone/src/elements/XmppElement.dart';

import '../XmppAttribute.dart';
import 'Nonza.dart';

class ResumedNonza extends Nonza {
  static String NAME = 'resumed';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(XmppElement nonza) =>
      (nonza.name == NAME && nonza.getAttribute('xmlns').value == XMLNS);

  ResumedNonza() {
    name = NAME;
    addAttribute(XmppAttribute('xmlns', XMLNS));
  }
}