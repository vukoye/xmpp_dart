import 'package:xmpp_stone/xmpp_stone.dart';

class MessageArchiveResult {
  final String id;
  final String lastStanzaId;
  final String firstStanzaId;
  final int count;

  const MessageArchiveResult(
      {required this.id,
      required this.lastStanzaId,
      required this.firstStanzaId,
      required this.count});

  static MessageArchiveResult parseFromXml(AbstractStanza stanza) {
    final fin = stanza.getChild('fin');
    if (fin != null) {
      final set = fin.getChild('set');
      if (set != null) {
        final count = set.getChild('count') != null
            ? int.tryParse(set.getChild('count')!.textValue!) ?? 0
            : 0;
        final first = set.getChild('first') != null
            ? set.getChild('first')!.textValue ?? ''
            : '';
        final last = set.getChild('last') != null
            ? set.getChild('last')!.textValue ?? ''
            : '';
        return MessageArchiveResult(
            count: count,
            firstStanzaId: first,
            lastStanzaId: last,
            id: stanza.id ?? '');
      }
    }
    return MessageArchiveResult(
        count: 0, lastStanzaId: '', firstStanzaId: '', id: stanza.id ?? '');
  }
}
