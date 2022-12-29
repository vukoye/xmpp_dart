import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/chat/Message.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/logger/Log.dart';

class ChatImpl implements Chat {
  static String TAG = 'Chat';

  final Connection _connection;
  final Jid _jid;

  @override
  Jid get jid => _jid;
  ChatState? _myState;

  @override
  ChatState? get myState => _myState;

  ChatState? _remoteState;
  @override
  ChatState? get remoteState => _remoteState;

  @override
  List<Message> messages = [];

  final StreamController<Message> _newMessageController =
      StreamController.broadcast();
  final StreamController<ChatState> _remoteStateController =
      StreamController.broadcast();

  @override
  Stream<Message> get newMessageStream => _newMessageController.stream;
  @override
  Stream<ChatState > get remoteStateStream =>
      _remoteStateController.stream;

  ChatImpl(this._jid, this._connection);

  bool _requestedChatState = false;

  void parseMessage(Message message) {
    if (message.type == MessageStanzaType.CHAT) {
      if (message.text != null && message.text!.isNotEmpty) {
        messages.add(message);
        _newMessageController.add(message);
      }

      if (message.chatState != null && !message.isDelayed) {
        _remoteState = message.chatState;
        _remoteStateController.add(message.chatState!);
      }
    }
  }

  @override
  void sendMessage(String text) {
    var stanza =
        MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
    stanza.toJid = _jid;
    stanza.fromJid = _connection.fullJid;
    stanza.body = text;
    if (_requestedChatState) {
      stanza.addChild(XmppElement('active')..addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates')));
    }
    stanza.addChild(
      XmppElement('markable')
        ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:chat-markers:0'))
    );
    var message = Message.fromStanza(stanza);
    messages.add(message);
    _newMessageController.add(message);
    _connection.writeStanza(stanza);
  }

  @override
  set myState(ChatState? state) {
    if (state != null) {
      var stanza =
          MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.CHAT);
      stanza.toJid = _jid;
      stanza.fromJid = _connection.fullJid;
      var stateElement =
          XmppElement(state.toString().split('.').last.toLowerCase());
      stateElement.addAttribute(
          XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates'));
      stanza.addChild(stateElement);
      _connection.writeStanza(stanza);
      _myState = state;
    }
  }

  @override
  void sendChatMarker(Message receivedMessage, ChatMarkerType markerType) {
    if (receivedMessage.messageId == null) {
      Log.e('Chat', 'Received urn:xmpp:chat-markers:0 message without message id ${receivedMessage.messageStanza.buildXml()}');
      return;
    }
    var stanza =
        MessageStanza(AbstractStanza.getRandomId(), null);
    stanza.toJid = receivedMessage.from;
    stanza.fromJid = _connection.fullJid;
    if (receivedMessage.threadId != null) {
      stanza.addChild(
        XmppElement('thread')
          ..textValue = receivedMessage.threadId
      );
    }

    late final String elementName;

    switch (markerType) {
      case ChatMarkerType.MARKABLE:
        Log.e('Chat', 'Cannot send standalone markable chat marker');
        return;
      case ChatMarkerType.RECEIVED:
        elementName = 'received';
        break;
      case ChatMarkerType.DISPLAYED:
        elementName = 'displayed';
        break;
      case ChatMarkerType.ACKNOWLEDGED:
        elementName = 'acknowledged';
        break;
    }
    
    stanza.addChild(
      XmppElement(elementName)
        ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:chat-markers:0'))
        ..addAttribute(XmppAttribute('id', receivedMessage.messageId!))
    );

    _connection.writeStanza(stanza);
  }
}

abstract class Chat {
  Jid get jid;
  ChatState? get myState;
  ChatState? get remoteState;
  Stream<Message> get newMessageStream;
  Stream<ChatState> get remoteStateStream;
  List<Message> messages = [];
  void sendMessage(String text);
  void sendChatMarker(Message receivedMessage, ChatMarkerType markerType);
  set myState(ChatState? state);
}

enum ChatState { INACTIVE, ACTIVE, GONE, COMPOSING, PAUSED }

enum ChatMarkerType { MARKABLE, RECEIVED, DISPLAYED, ACKNOWLEDGED  }
