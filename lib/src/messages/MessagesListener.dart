import 'package:xmpp_stone_obelisk/src/elements/stanzas/MessageStanza.dart';

abstract class MessagesListener {
  void onNewMessage(MessageStanza? message);
}
