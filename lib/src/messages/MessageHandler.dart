import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/extensions/advanced_messaging_processing/AmpManager.dart';
import 'package:xmpp_stone/src/extensions/chat_states/ChatStateDecoration.dart';
import 'package:xmpp_stone/src/extensions/message_delivery/ReceiptInterface.dart';
import 'package:xmpp_stone/src/messages/MessageApi.dart';
import 'package:xmpp_stone/src/messages/MessageParams.dart';
import 'package:xmpp_stone/src/response/response.dart';

class MessageHandler implements MessageApi {
  static Map<Connection?, MessageHandler> instances =
      <Connection?, MessageHandler>{};

  final ResponseHandler<MessageStanza> responseHandler =
      ResponseHandler<MessageStanza>();

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
          chatStateType: ChatStateType.None,
          ampMessageType: AmpMessageType.None,
          options: XmppCommunicationConfig(shallWaitStanza: false))}) {
    return _sendMessageStanza(to, text, additional);
  }

  Future<MessageStanza> sendState(
    Jid? to,
    MessageStanzaType messageType,
    ChatStateType chatStateType,
  ) {
    return _sendMessageStanza(
        to,
        '',
        MessageParams(
            millisecondTs: 0,
            customString: '',
            messageId: '',
            receipt: ReceiptRequestType.NONE,
            messageType: messageType,
            chatStateType: chatStateType,
            ampMessageType: AmpMessageType.None,
            options: XmppCommunicationConfig(shallWaitStanza: false)));
  }

  Future<MessageStanza> _sendMessageStanza(
      Jid? jid, String text, MessageParams additional) async {
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
    }

    if (additional.ampMessageType == AmpMessageType.Delivery) {
      // Add request stanza from server?
      stanza.addAmpDeliverDirect();
    }

    if (additional.millisecondTs != 0) {
      stanza.addTime(additional.millisecondTs);
    }

    if (additional.customString.isNotEmpty) {
      stanza.addCustom(additional.customString);
    }

    if (additional.chatStateType != ChatStateType.None) {
      ChatStateDecoration(message: stanza).setState(additional.chatStateType);
    }

    print(stanza.buildXmlString());
    _connection!.writeStanza(stanza);

    return stanza;
    // Could not wait for the ack, there is no ack sent (r, c type)
    // return responseHandler.set<MessageStanza>(stanza.id!, stanza);
  }

  void _connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.Ready) {
      _connection!.streamManagementModule.deliveredStanzasStream
          .where((abstractStanza) => abstractStanza is MessageStanza)
          .map((stanza) => stanza as MessageStanza)
          .listen(_processDeliveryStanza);
    }
  }

  void _processDeliveryStanza(AbstractStanza nonza) {
    responseHandler.test(nonza.id!, (item) {
      switch (item.item3) {
        case MessageStanza:
          item.item2.complete(item.item1);
          break;
      }
    });
  }
}
