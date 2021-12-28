import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/extensions/message_delivery/ReceiptInterface.dart';

class MessageParams {
  final ReceiptRequestType receipt; // = ReceiptRequestType.NONE;
  final String messageId;
  final int millisecondTs;
  final String customString;
  final MessageStanzaType messageType; // = MessageStanzaType.CHAT;
  final XmppCommunicationConfig options;

  const MessageParams({
    required this.receipt,
    required this.messageId,
    required this.millisecondTs,
    required this.customString,
    required this.messageType,
    required this.options,
  });

  static MessageParams build({
    ReceiptRequestType receipt = ReceiptRequestType.NONE,
    String messageId = '',
    int millisecondTs = 0,
    String customString = '',
    MessageStanzaType messageType = MessageStanzaType.CHAT,
    XmppCommunicationConfig options =
        const XmppCommunicationConfig(shallWaitStanza: false),
  }) {
    return MessageParams(
        receipt: receipt,
        messageId: messageId,
        millisecondTs: millisecondTs,
        customString: customString,
        messageType: messageType,
        options: options);
  }
}
