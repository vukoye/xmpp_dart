import 'package:xmppstone/src/elements/stanzas/MessageStanza.dart';

abstract class MessagesListener {
  onNewMessage(MessageStanza message);
}