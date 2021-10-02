import 'package:xmpp_stone/src/data/Jid.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text);
  void sendMessageRequestReceipt(Jid to, String text);
  void sendMessageReceipt(Jid to, String text, String messageId);
}
