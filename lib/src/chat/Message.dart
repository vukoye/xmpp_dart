import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';

class Message {
  MessageStanza _messageStanza;

  MessageStanza get messageStanza => _messageStanza;

  set messageStanza(MessageStanza value) {
    _messageStanza = value;
  }

  Jid _to;
  Jid _from;
  String _text;
  DateTime _time;


  Message(this._messageStanza, this._to, this._from, this._text, this._time);

  static Message fromStanza(MessageStanza stanza) {
    return Message(stanza, stanza.toJid, stanza.fromJid, stanza.body, DateTime.now());
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
}
