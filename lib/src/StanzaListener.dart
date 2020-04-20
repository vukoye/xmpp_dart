import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

abstract class StanzaProcessor {
  processStanza(AbstractStanza stanza);
}
