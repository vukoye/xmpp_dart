import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/messages/MessageApi.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class MessageHandler implements MessageApi {
  static Map<Connection, MessageHandler> instances =
      <Connection, MessageHandler>{};

  Stream<MessageStanza> get messagesStream {
    return _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is MessageStanza)
        .map((stanza) => stanza as MessageStanza);
  }

  static MessageHandler getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = MessageHandler(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  Connection _connection;

  MessageHandler(Connection connection) {
    _connection = connection;
  }

  @override
  void sendMessage(Jid to, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int millisecondTs = 0}) {
    _sendMessageStanza(to, text,
        receipt: receipt, messageId: messageId, millisecondTs: millisecondTs);
  }

  void _sendMessageStanza(Jid jid, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int millisecondTs = 0}) {
    final stanza = MessageStanza(
        messageId.isEmpty ? AbstractStanza.getRandomId() : messageId,
        MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    if (text.isNotEmpty) {
      stanza.body = text;
    }

    // Add receipt delivery
    if (receipt == ReceiptRequestType.RECEIVED) {
      stanza.addReceivedReceipt();
    } else if (receipt == ReceiptRequestType.REQUEST) {
      stanza.addRequestReceipt();
    }

    if (millisecondTs != 0) {
      stanza.addTime(millisecondTs);
    }
    print(stanza.buildXmlString());
    _connection.writeStanza(stanza);
  }
}
