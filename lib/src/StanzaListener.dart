import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';

abstract class StanzaProcessor {
  processStanza(AbstractStanza stanza);
}