import 'package:xmppstone/src/data/Jid.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text);
}