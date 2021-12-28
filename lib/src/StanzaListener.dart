import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

abstract class StanzaProcessor {
  void processStanza(AbstractStanza stanza);
}
