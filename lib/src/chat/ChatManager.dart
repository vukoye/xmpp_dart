import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/chat/Chat.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class ChatManager {
  static Map<Connection, ChatManager> instances = {};

  static ChatManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = ChatManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  final Connection _connection;

  ChatManager(this._connection) {
    _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is MessageStanza)
        .map((stanza) => stanza as MessageStanza?)
        .listen((stanza) {
          var message = Message.fromStanza(stanza!);
          // find jid different from mine
          var buddyJid = _connection.fullJid.userAtDomain == message.to!.userAtDomain ?
              message.from! : message.to!;
      var chat = _getChat(buddyJid);
      chat.parseMessage(message);
    });
  }

  final StreamController<List<Chat>> _chatListStreamController =
      StreamController.broadcast();

  Stream<List<Chat>> get chatListStream => _chatListStreamController.stream;

  final Map<String, ChatImpl> _chats = {};

  List<Chat> get chats {
    var chatList = _chats.values.toList();
    return chatList;
  }

  Chat getChat(Jid jid) {
    return _getChat(jid);
  }

  ChatImpl _getChat(Jid jid) {
    var chat = _chats[jid.userAtDomain];
    if (chat == null) {
      chat = ChatImpl(jid, _connection);
      _chats[jid.userAtDomain] = chat;
      _chatListStreamController.add(chats);
    }
    return chat;
  }
}
