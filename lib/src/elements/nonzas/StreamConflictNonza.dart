import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class StreamConflictNonza extends Nonza {
  static String NAME = 'error';
  static String CONFLICT_NAME = 'conflict';
  static String XMLNS = 'urn:ietf:params:xml:ns:xmpp-streams';

  static bool match(Nonza nonza) => (nonza.name == NAME &&
      nonza.getChild(CONFLICT_NAME) != null &&
      nonza.getChild(CONFLICT_NAME)!.getAttribute('xmlns')!.value == XMLNS);

  StreamConflictNonza() {
    name = NAME;
  }
}
