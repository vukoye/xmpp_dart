import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/extensions/message_delivery/ReceiptInterface.dart';
import 'package:xmpp_stone/src/messages/MessageApi.dart';
import 'package:xmpp_stone/src/messages/MessageParams.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

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
      {MessageParams additional = const MessageParams(
          millisecondTs: 0,
          customString: '',
          messageId: '',
          receipt: ReceiptRequestType.NONE,
          messageType: MessageStanzaType.CHAT,
          options: XmppCommunicationConfig(shallWaitStanza: false))}) {
    return _sendMessageStanza(to, text, additional);
  }

  Future<MessageStanza> _sendMessageStanza(
      Jid? jid, String text, MessageParams additional) {
    var completer = Completer<MessageStanza>();
    final stanza = MessageStanza(
        additional.messageId.isEmpty
            ? AbstractStanza.getRandomId()
            : additional.messageId,
        additional.messageType);
    stanza.toJid = jid;
    stanza.fromJid = _connection!.fullJid;
    if (text.isNotEmpty) {
      stanza.body = text;
    }

    // Add receipt delivery
    if (additional.receipt == ReceiptRequestType.RECEIVED) {
      stanza.addReceivedReceipt();
    } else if (additional.receipt == ReceiptRequestType.REQUEST) {
      stanza.addRequestReceipt();
      // Add request stanza from server?
      stanza.addAmpDeliverDirect();
    }

    if (additional.millisecondTs != 0) {
      stanza.addTime(additional.millisecondTs);
    }

    if (additional.customString.isNotEmpty) {
      stanza.addCustom(additional.customString);
    }

    print(stanza.buildXmlString());
    _connection!.writeStanza(stanza);

    _myUnrespondedIqStanzas[stanza.id] = Tuple2(stanza, completer);

    if (!additional.options.shallWaitStanza) {
      Timer(Duration(milliseconds: 200), () {
        if (_myUnrespondedIqStanzas.containsKey(stanza.id)) {
          _myUnrespondedIqStanzas[stanza.id]!
              .item2
              .complete(_myUnrespondedIqStanzas[stanza.id]!.item1);
          _myUnrespondedIqStanzas
              .remove(_myUnrespondedIqStanzas[stanza.id]!.item1.id);
        }
      });
    }
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
