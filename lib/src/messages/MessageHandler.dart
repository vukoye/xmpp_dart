import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone_obelisk/src/Connection.dart';
import 'package:xmpp_stone_obelisk/src/data/Jid.dart';
import 'package:xmpp_stone_obelisk/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone_obelisk/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone_obelisk/src/extensions/message_delivery/ReceiptInterface.dart';
import 'package:xmpp_stone_obelisk/src/messages/MessageApi.dart';
import 'package:xmpp_stone_obelisk/xmpp_stone.dart';

class MessageHandler implements MessageApi {
  static Map<Connection?, MessageHandler> instances =
      <Connection?, MessageHandler>{};

  final Map<String?, Tuple2<MessageStanza, Completer>> _myUnrespondedIqStanzas =
      <String?, Tuple2<MessageStanza, Completer>>{};

  Stream<MessageStanza?> get messagesStream {
    return _connection!.inStanzasStream.where((abstractStanza) {
      return abstractStanza is MessageStanza;
    }).map((stanza) => stanza as MessageStanza?);
  }

  static MessageHandler getInstance(Connection? connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = MessageHandler(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  Connection? _connection;

  MessageHandler(Connection? connection) {
    _connection = connection;

    _connection!.connectionStateStream.listen(_connectionStateHandler);
  }

  @override
  Future<MessageStanza> sendMessage(Jid? to, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int? millisecondTs = 0,
      String customString = '',
      MessageStanzaType messageType = MessageStanzaType.CHAT}) {
    return _sendMessageStanza(to, text,
        receipt: receipt,
        messageId: messageId,
        millisecondTs: millisecondTs,
        customString: customString,
        messageType: messageType);
  }

  Future<MessageStanza> _sendMessageStanza(Jid? jid, String text,
      {ReceiptRequestType receipt = ReceiptRequestType.NONE,
      String messageId = '',
      int? millisecondTs = 0,
      String customString = '',
      MessageStanzaType messageType = MessageStanzaType.CHAT}) {
    var completer = Completer<MessageStanza>();
    final stanza = MessageStanza(
        messageId.isEmpty ? AbstractStanza.getRandomId() : messageId,
        messageType);
    stanza.toJid = jid;
    stanza.fromJid = _connection!.fullJid;
    if (text.isNotEmpty) {
      stanza.body = text;
    }

    // Add receipt delivery
    if (receipt == ReceiptRequestType.RECEIVED) {
      stanza.addReceivedReceipt();
    } else if (receipt == ReceiptRequestType.REQUEST) {
      stanza.addRequestReceipt();
      // Add request stanza from server?
      stanza.addAmpDeliverDirect();
    }

    if (millisecondTs != 0) {
      stanza.addTime(millisecondTs);
    }

    if (customString.isNotEmpty) {
      stanza.addCustom(customString);
    }

    print(stanza.buildXmlString());
    _connection!.writeStanza(stanza);

    _myUnrespondedIqStanzas[stanza.id] = Tuple2(stanza, completer);
    return completer.future;
  }

  void _connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.SessionInitialized) {
      _connection!.streamManagementModule.deliveredStanzasStream
          .where((abstractStanza) => abstractStanza is MessageStanza)
          .map((stanza) => stanza as MessageStanza)
          .listen(_processDeliveryStanza);
    }
  }

  void _processDeliveryStanza(AbstractStanza nonza) {
    var unrespondedStanza = _myUnrespondedIqStanzas[nonza.id];
    if (unrespondedStanza != null) {
      unrespondedStanza.item2.complete(unrespondedStanza.item1);
      _myUnrespondedIqStanzas.remove(unrespondedStanza.item1.id);
    }
  }
}
