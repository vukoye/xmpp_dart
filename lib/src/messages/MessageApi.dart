import 'package:xmpp/src/data/Jid.dart';

abstract class MessageApi {
  void sendMessage(Jid to, String text);
}