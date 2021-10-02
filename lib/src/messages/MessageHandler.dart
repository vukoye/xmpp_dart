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
  void sendMessage(Jid to, String text) {
    _sendMessageStanza(to, text);
  }

  @override
  void sendMessageRequestReceipt(Jid to, String text) {
    _sendMessageStanzaReceipt(to, text, request: true);
  }
  @override
  void sendMessageReceipt(Jid to, String text, String messageId) {
    _sendMessageStanzaReceipt(to, text, request: false, messageId: messageId);
  }

  void _sendMessageStanza(Jid jid, String text) {
    var stanza =
        MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    print(stanza.buildXmlString());
    _connection.writeStanza(stanza);
  }

  void _sendMessageStanzaReceipt(Jid jid, String text, { bool request = false, String messageId }) {
    var stanza =
        MessageReceiptsStanza(request ? AbstractStanza.getRandomId() : messageId , MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = request ? text : '';
    stanza.receipts = request ? 'request' : 'received';
    print(stanza.buildXmlString());
    _connection.writeStanza(stanza);
  }
}
