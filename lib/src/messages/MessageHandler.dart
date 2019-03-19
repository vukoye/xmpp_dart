import 'package:xmpp/src/StanzaListener.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp/src/messages/MessageApi.dart';
import 'package:xmpp/xmpp.dart';

class MessageHandler implements MessageApi, StanzaProcessor {

  static Map<Connection, MessageHandler> instances = Map<Connection, MessageHandler>();

  Stream<MessageStanza> get messagesStream {
    return _connection.stanzasStream.where((abstractStanza)  => abstractStanza is MessageStanza).map((stanza) => stanza as MessageStanza);
  }

  static getInstance(Connection connection) {
    MessageHandler manager = instances[connection];
    if (manager == null) {
      manager = MessageHandler(connection);
      instances[connection] = manager;
      connection.stanzasStream.listen(manager.processStanza);
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
  processStanza(AbstractStanza stanza) {
    if (stanza is MessageStanza) {

    }
    return null;
  }

  void _sendMessageStanza(Jid jid, String text) {
    MessageStanza stanza = new MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    _connection.writeStanza(stanza);
  }

}