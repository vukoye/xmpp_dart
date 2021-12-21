import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int millisecondTs = 0});
}
