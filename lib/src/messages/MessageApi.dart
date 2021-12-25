import 'package:xmpp_stone_obelisk/src/data/Jid.dart';
import 'package:xmpp_stone_obelisk/src/messages/MessageParams.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text, {MessageParams additional});
}
