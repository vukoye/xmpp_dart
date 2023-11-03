import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/chat/Message.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';
import 'package:xmpp_stone/src/logger/Log.dart';

class ChatImpl implements Chat {
  static String TAG = 'Chat';

  final Connection _connection;
  final Jid _jid;
  final StreamManagementModule _smm;

  @override
  Jid get jid => _jid;
  ChatState? _myState;
  @override
  ChatState? get myState => _myState;

  ChatState? _remoteState;
  @override
  ChatState? get remoteState => _remoteState;

  @override
  List<Message>? messages = [];

  final StreamController<Message> _newMessageController =
      StreamController.broadcast();
  final StreamController<Message> _newChatMarkerController =
      StreamController.broadcast();
  final StreamController<ChatState?> _remoteStateController =
      StreamController.broadcast();

  @override
  Stream<Message> get newMessageStream => _newMessageController.stream;
  @override
  Stream<Message> get newChatMarkerStream => _newChatMarkerController.stream;
  @override
  Stream<ChatState?> get remoteStateStream => _remoteStateController.stream;

  ChatImpl(this._jid, this._connection)
      : _smm = StreamManagementModule.getInstance(_connection);

  bool _requestedChatState = false;

  void parseMessage(Message message) {
    if (message.chatMarkerType != null &&
        message.chatMarkerType != ChatMarkerType.MARKABLE) {
      _newChatMarkerController.add(message);
    }
    if (message.type == MessageStanzaType.CHAT ||
        message.type == MessageStanzaType.GROUPCHAT) {
      if (message.text != null && message.text!.isNotEmpty) {
        messages!.add(message);
        _newMessageController.add(message);
      }

      if (message.chatState != null && !(message.isDelayed ?? false)) {
        _remoteState = message.chatState;
        _remoteStateController.add(message.chatState!);
      }
    }
  }

  @override
  Future<String> sendMessage(
    String text, {
    String? messageId,
    bool isGroupChat = false,
  }) async {
    messageId ??= AbstractStanza.getRandomId();
    final stanza = composeMessage(
      text,
      messageId: messageId,
      fromJid: _connection.fullJid,
      toJid: _jid,
      type: isGroupChat ? MessageStanzaType.GROUPCHAT : MessageStanzaType.CHAT,
    );
    if (_requestedChatState) {
      stanza.addChild(XmppElement('active')
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/chatstates')));
    }
    stanza.addChild(XmppElement('markable')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:chat-markers:0')));
    stanza.addChild(XmppElement('request')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:receipts')));
    stanza.addChild(XmppElement('origin-id')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:sid:0'))
      ..addAttribute(XmppAttribute('id', messageId)));

    var message = Message.fromStanza(stanza).first;
    messages!.add(message);
    _newMessageController.add(message);
    _connection.writeStanza(stanza);
    await _smm.deliveredStanzasStream
        .firstWhere((element) => element.id == messageId);
    return messageId;
  }

  static MessageStanza composeMessage(
    String text, {
    MessageStanzaType type = MessageStanzaType.CHAT,
    String? messageId,
    Jid? fromJid,
    Jid? toJid,
  }) {
    final stanza = MessageStanza(
      messageId,
      type: type,
    );
    if (fromJid != null) {
      stanza.fromJid = fromJid;
    }
    if (toJid != null) {
      stanza.toJid = toJid;
    }
    stanza.body = text;
    return stanza;
  }

  @override
  void setChatState(
    ChatState? state, {
    bool isGroupChat = false,
  }) {
    var stanza = MessageStanza(
      AbstractStanza.getRandomId(),
      type: isGroupChat ? MessageStanzaType.GROUPCHAT : MessageStanzaType.CHAT,
    );
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

  @override
  Future<String> sendChatMarker(
      Jid toJid, String messageId, ChatMarkerType markerType,
      {String? threadId}) async {
    final stanza = MessageStanza(AbstractStanza.getRandomId());
    stanza.toJid = toJid;
    stanza.fromJid = _connection.fullJid;
    if (threadId != null) {
      stanza.addChild(XmppElement('thread')..textValue = threadId);
    }

    late final String elementName;

    switch (markerType) {
      case ChatMarkerType.MARKABLE:
        Log.e('Chat', 'Cannot send standalone markable chat marker');
        throw ArgumentError.value(
          markerType,
          'markerType',
          'Cannot send standalone markable chat marker',
        );
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

    stanza.addChild(XmppElement(elementName)
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:chat-markers:0'))
      ..addAttribute(XmppAttribute('id', messageId)));

    stanza.addChild(XmppElement('store')
      ..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:hints')));

    _newChatMarkerController.add(Message.fromStanza(stanza).first);
    _connection.writeStanza(stanza);
    await _smm.deliveredStanzasStream
        .firstWhere((element) => element.id == messageId);
    return messageId;
  }
}

abstract class Chat {
  Jid get jid;
  ChatState? get myState;
  ChatState? get remoteState;
  Stream<Message> get newMessageStream;
  Stream<Message> get newChatMarkerStream;
  Stream<ChatState?> get remoteStateStream;
  Future<String> sendMessage(
    String text, {
    String? messageId,
    bool isGroupChat = false,
  });
  Future<String> sendChatMarker(
      Jid toJid, String messageId, ChatMarkerType markerType,
      {String? threadId});
  List<Message>? messages;
  void setChatState(
    ChatState? state, {
    bool isGroupChat = false,
  });
}

enum ChatState { INACTIVE, ACTIVE, GONE, COMPOSING, PAUSED }

enum ChatMarkerType { MARKABLE, RECEIVED, DISPLAYED, ACKNOWLEDGED }
