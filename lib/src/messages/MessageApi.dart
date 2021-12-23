import 'package:xmpp_stone_obelisk/src/data/Jid.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/ReceiptInterface.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int millisecondTs = 0});
}
