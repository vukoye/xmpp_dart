import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/StanzaListener.dart';
import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmppstone/src/messages/MessageApi.dart';

class MessageHandler implements MessageApi {

  static Map<Connection, MessageHandler> instances = Map<Connection, MessageHandler>();

  Stream<MessageStanza> get messagesStream {
    return _connection.inStanzasStream.where((abstractStanza)  => abstractStanza is MessageStanza).map((stanza) => stanza as MessageStanza);
  }

  static getInstance(Connection connection) {
    MessageHandler manager = instances[connection];
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

  void _sendMessageStanza(Jid jid, String text) {
    MessageStanza stanza = new MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    _connection.writeStanza(stanza);
  }

}