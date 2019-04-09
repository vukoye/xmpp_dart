import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/chat/Message.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/messages/MessageHandler.dart';



class ChatImpl implements Chat{

  Connection _connection;
  Jid _jid;

  Jid get jid => _jid;
  ChatState _myState;
  ChatState get myState => _myState;

  ChatState _remoteState;
  ChatState get remoteState => _remoteState;

  List<Message> messages  = List();

  StreamController<Message> _newMessageController = new StreamController.broadcast();
  StreamController<ChatState> _remoteStateController = new StreamController.broadcast();

  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<ChatState> get remoteStateStream => _remoteStateController.stream;

  ChatImpl(this._jid, this._connection);


  void parseMessage(MessageStanza stanza) {
    if (stanza.type == MessageStanzaType.CHAT) {
      if (stanza.body.isNotEmpty) {
        Message message = Message.fromStanza(stanza);
        messages.add(message);
        _newMessageController.add(message);
      }
      var stateElement = stanza.children.firstWhere((element) => element.getAttribute("xmlns").value == "http://jabber.org/protocol/chatstates", orElse: () => null);
      if (stateElement != null) {
        var state = stateFromString(stateElement.name);
        _remoteState = state;
        _remoteStateController.add(state);
      }
    }
  }

  void sendMessage(String text) {
    MessageStanza stanza = new MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = _jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    Message message = Message.fromStanza(stanza);
    messages.add(message);
    _newMessageController.add(message);
    _connection.writeStanza(stanza);
  }

  void set myState(ChatState state) {
    MessageStanza stanza = new MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = _jid;
    stanza.fromJid = _connection.fullJid;
    XmppElement stateElement = XmppElement();
    stateElement.name = state.toString().split('.').last.toLowerCase();
    stateElement.addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
    stanza.addChild(stateElement);
    _connection.writeStanza(stanza);
    _myState = state;
  }

  static ChatState stateFromString(String chatStateString) {
    switch(chatStateString) {
      case "inactive":
        return ChatState.INACTIVE;
      case "active":
        return ChatState.ACTIVE;
      case "gone":
        return ChatState.GONE;
      case "composing":
        return ChatState.COMPOSING;
      case "paused":
        return ChatState.PAUSED;
    }
    return ChatState.INACTIVE;
  }
}

abstract class Chat {
  Jid get jid;
  ChatState get myState;
  ChatState get remoteState;
  Stream<Message> get newMessageStream;
  Stream<ChatState> get remoteStateStream;
  void sendMessage(String text);
  void set myState(ChatState state);
}

enum ChatState {
  INACTIVE, ACTIVE, GONE, COMPOSING, PAUSED
}

