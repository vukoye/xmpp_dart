import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';

abstract class MessagesListener {
  onNewMessage(MessageStanza message);
}
