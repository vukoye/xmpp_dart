import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/chat/Chat.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class ChatManager {
  static Map<Connection, ChatManager> instances =
      Map<Connection, ChatManager>();

  static getInstance(Connection connection) {
    ChatManager manager = instances[connection];
    if (manager == null) {
      manager = ChatManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  Connection _connection;

  ChatManager(this._connection) {
    _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is MessageStanza)
        .map((stanza) => stanza as MessageStanza)
        .listen((stanza) {
      var chat = _getChat(stanza.fromJid);
      chat.parseMessage(stanza);
    });
  }

  StreamController<List<Chat>> _chatListStreamController =
      StreamController.broadcast();

  Stream<List<Chat>> get chatListStream => _chatListStreamController.stream;

  Map<String, ChatImpl> _chats = Map<String, ChatImpl>();

  List<Chat> get chats {
    List<Chat> chatList = _chats.values.toList();
    return chatList;
  }

  Chat getChat(Jid jid) {
    return _getChat(jid);
  }

  ChatImpl _getChat(Jid jid) {
    Chat chat = _chats[jid];
    if (chat == null) {
      chat = ChatImpl(jid, _connection);
      _chats[jid.userAtDomain] = chat;
      _chatListStreamController.add(chats);
    }
    return chat;
  }
}
