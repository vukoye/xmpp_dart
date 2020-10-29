import 'package:xmpp_stone/src/chat/Chat.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import '../elements/XmppElement.dart';
import '../elements/stanzas/MessageStanza.dart';
import '../logger/Log.dart';

class Message {
  static String TAG = 'Message';
  MessageStanza _messageStanza;

  MessageStanza get messageStanza => _messageStanza;

  set messageStanza(MessageStanza value) {
    _messageStanza = value;
  }

  Jid _to;
  Jid _from;
  String _text;
  DateTime _time;

  //TODO: check purpose vs stanza_id
  String _messageId;
  String _stanzaId;
  String _threadId;
  String _queryId; //To be determined if needed
  bool _isDelayed;
  bool _isForwarded;
  MessageStanzaType _type;

  ChatState _chatState; // optional element

  String get messageId => _messageId;

  Message(this._messageStanza, this._to, this._from, this._text, this._time,
      {String stanzaId = '',
      String threadId = '',
      bool isForwarded = false,
      bool isDelayed,
      String queryId,
      String messageId,
      MessageStanzaType type,
      ChatState chatState}) {
    _stanzaId = stanzaId;
    _threadId = threadId;
    _isForwarded = isForwarded;
    _isDelayed = isDelayed;
    _queryId = queryId;
    _messageId = messageId;
    _type = type;
    _chatState = chatState;
  }

  ChatState get chatState => _chatState;

  static Message fromStanza(MessageStanza stanza) {
    Message message;
    var isCarbon = stanza.children.any(
        (element) => (element.name == 'sent' || element.name == 'received'));
    var isArchivedMessage =
        stanza.children.any((element) => (element.name == 'result'));
    if (isCarbon) {
      message = _parseCarbon(stanza);
    } else if (isArchivedMessage) {
      message = _parseArchived(stanza);
    }
    message ??= _parseRegularMessage(stanza);
    return message;
  }

  static Message _parseCarbon(MessageStanza stanza) {
    var carbon = stanza.children.firstWhere(
        (element) => (element.name == 'sent' || element.name == 'received'),
        orElse: () => null);
    try {
      var forwarded = carbon.getChild('forwarded');
      if (forwarded != null) {
        var message = forwarded.getChild('message');
        if (message != null) {
          var to = Jid.fromFullJid(message.getAttribute('to')?.value);
          var from = Jid.fromFullJid(message.getAttribute('from')?.value);
          var body = message.getChild('body')?.textValue;
          var type = (_parseType(message));
          var chatState = _parseState(message);
          var threadId = message.getChild('thread')?.textValue;
          var dateTime = _parseDelayed(forwarded);
          var delayed = dateTime != null;
          dateTime ??= DateTime.now();
          return Message(stanza, to, from, body, dateTime,
              threadId: threadId,
              isForwarded: true,
              isDelayed: delayed,
              chatState: chatState,
              type: type);
        }
      }
    } catch (e) {
      Log.e(TAG, 'Error while parsing message');
    }
    return null;
  }

  static Message _parseArchived(MessageStanza stanza) {
    var result = stanza.children.firstWhere(
        (element) => (element.name == 'result'),
        orElse: () => null);
    try {
      var queryId = result?.getAttribute('queryId')?.value;
      var forwarded = result.getChild('forwarded');
      if (forwarded != null) {
        var message = forwarded.getChild('message');
        if (message != null) {
          var to = Jid.fromFullJid(message.getAttribute('to')?.value);
          var from = Jid.fromFullJid(message.getAttribute('from')?.value);
          var body = message.getChild('body')?.textValue;
          var threadId = message.getChild('thread')?.textValue;
          var stanzaId =
              message.getChild('stanza-id')?.getAttribute('id')?.value;
          var type = (_parseType(message));
          var dateTime = _parseDelayed(forwarded);
          dateTime ??= DateTime.now();
          var delayed = dateTime != null;
          var chatState = _parseState(message);
          return Message(stanza, to, from, body, dateTime,
              threadId: threadId,
              isForwarded: true,
              queryId: queryId,
              isDelayed: delayed,
              stanzaId: stanzaId,
              chatState: chatState,
              type: type);
        }
      }
    } catch (e) {
      Log.e(TAG, 'Error while parsing archived message ${e}');
    }
    return null;
  }

  static MessageStanzaType _parseType(XmppElement element) {
    var typeString = element.getAttribute('type');
    MessageStanzaType type;
    if (typeString == null) {
      Log.w(TAG, 'No type found for iq stanza');
    } else {
      switch (typeString.value) {
        case 'chat':
          type = MessageStanzaType.CHAT;
          break;
        case 'error':
          type = MessageStanzaType.ERROR;
          break;
        case 'groupchat':
          type = MessageStanzaType.GROUPCHAT;
          break;
        case 'headline':
          type = MessageStanzaType.HEADLINE;
          break;
        case 'normal':
          type = MessageStanzaType.NORMAL;
          break;
      }
    }
    return type;
  }

  static ChatState _parseState(XmppElement element) {
    var stateElement = element.children.firstWhere(
        (element) =>
            element.getAttribute('xmlns')?.value ==
            'http://jabber.org/protocol/chatstates',
        orElse: () => null);
    if (stateElement != null) {
      return _stateFromString(stateElement.name);
    } else {
      return null;
    }
  }

  static ChatState _stateFromString(String chatStateString) {
    switch (chatStateString) {
      case 'inactive':
        return ChatState.INACTIVE;
      case 'active':
        return ChatState.ACTIVE;
      case 'gone':
        return ChatState.GONE;
      case 'composing':
        return ChatState.COMPOSING;
      case 'paused':
        return ChatState.PAUSED;
    }
    return ChatState.INACTIVE;
  }

  static Message _parseRegularMessage(MessageStanza stanza) {
    return Message(
        stanza, stanza.toJid, stanza.fromJid, stanza.body, DateTime.now(),
        chatState: _parseState(stanza),
        threadId: stanza.thread,
        type: _parseType(stanza));
  }

  static DateTime _parseDelayed(XmppElement element) {
    var delayed = element.getChild('delay');
    if (delayed != null) {
      var stamped = delayed.getAttribute('stamp').value;
      try {
        var dateTime = DateTime.parse(stamped);
        return dateTime;
      } catch (e) {
        Log.e(TAG, 'Date Parsing problem');
      }
    }
    return null;
  }

  Jid get to => _to;

  set to(Jid value) {
    _to = value;
  }

  Jid get from => _from;

  set from(Jid value) {
    _from = value;
  }

  String get text => _text;

  set text(String value) {
    _text = value;
  }

  DateTime get time => _time;

  set time(DateTime value) {
    _time = value;
  }

  String get stanzaId => _stanzaId;

  String get threadId => _threadId;

  String get queryId => _queryId;

  bool get isDelayed => _isDelayed;

  bool get isForwarded => _isForwarded;

  MessageStanzaType get type => _type;
}
