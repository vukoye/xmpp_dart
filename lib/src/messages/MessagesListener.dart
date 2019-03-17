import 'package:xmpp/src/elements/stanzas/MessageStanza.dart';

abstract class MessagesListener {
  onNewMessage(MessageStanza message);
}