import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/messages/MessageParams.dart';

abstract class MessageApi {
  Future<MessageStanza> sendMessage(Jid to, String text,
      {MessageParams additional});
  Future<MessageStanza> sendSecureMessage(Jid to, EncryptElement encryptElement,
      {MessageParams additional});
}
