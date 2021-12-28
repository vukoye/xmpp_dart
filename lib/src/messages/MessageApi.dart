import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/messages/MessageParams.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text, {MessageParams additional});
}
