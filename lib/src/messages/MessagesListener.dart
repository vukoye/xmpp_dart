import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';

abstract class MessagesListener {
  void onNewMessage(MessageStanza message);
}
