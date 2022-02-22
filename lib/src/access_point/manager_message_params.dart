import 'dart:convert';

import 'package:xmpp_stone/src/extensions/chat_states/ChatStateDecoration.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class XMPPMessageParams {
  final xmpp.MessageStanza? message;
  const XMPPMessageParams({this.message});

  bool get isEncrypted {
    return message!.getChild('encrypted') != null;
  }

  xmpp.OMEMOEnvelopeEncryptionParams? getEncryptedMessage() {
    final result = xmpp.EncryptElement.parseEncryption(message);
    return result != null ? result.item2 : null;
  }

  bool _isCustomDelivery() {
    if (_isCustomAck()) {
      return ['Delivery-Ack-Group', 'Delivery-Ack']
          .contains(getCustomData!['iqType']);
    } else if (isReceiptDelivered) {
      return true;
    } else {
      return false;
    }
  }

  bool _isCustomRead() {
    if (_isCustomAck()) {
      return [
        'Read-Ack-Group',
        'Read-Ack',
      ].contains(getCustomData!['iqType']);
    } else {
      return false;
    }
  }

  bool isCustomAny() {
    return message!.getCustom() != null;
  }

  bool _isCustomAck() {
    return message!.getCustom() != null && getCustomData!.containsKey('iqType');
  }

  bool _isCustomMessage() {
    return message!.getCustom() != null &&
        !getCustomData!.containsKey('iqType');
  }

  bool get isMessageCustom {
    return _isCustomMessage(); // body can contain some data
  }

  bool get isMessage {
    return message!.body != null && message!.getCustom() == null;
  }

  bool get isOnlyMessage {
    return !(isAckDeliveryClient ||
        isAckDeliveryDirect ||
        isAckDeliveryStored ||
        isAckReadClient ||
        isDelay ||
        isCarbon ||
        isGroupInvitationMessage ||
        _isCustomAck());
  }

  bool get isRequestingReceipt {
    return message!.getRequestReceipt() != null;
  }

  bool get isReceiptDelivered {
    return message!.getReceivedReceipt() != null;
  }

  bool get isAckDeliveryDirect {
    return message!.body == null && message!.isAmpDeliverDirect();
  }

  bool get isAckDeliveryStored {
    return message!.body == null && message!.isAmpDeliverStore();
  }

  bool get isAckDeliveryClient {
    return _isCustomDelivery();
  }

  bool get isAckReadClient {
    return _isCustomRead();
  }

  bool get isDelay {
    return message!.getDelay() != null;
  }

  String? get delayedMessageType {
    return message!.getDelay() != null ? message!.getDelay()!.textValue : 'N/A';
  }

  bool get isCarbon {
    return message!.getSent() != null;
  }

  bool get isArchive {
    return message!.getArchiveResult() != null;
  }

  bool get hasStanzaArchiveId {
    return message!.getStanzaId() != null;
  }

  bool get isGroupInvitationMessage {
    return message!.getInvitation() != null;
  }

  xmpp.XmppElement? get archiveMessage {
    return isArchive ? message!.getArchiveMessage() : null;
  }

  bool get isChatState {
    return ChatStateDecoration(
            message:
                message ?? xmpp.MessageStanza('', xmpp.MessageStanzaType.NONE))
        .hasState;
  }

  ChatStateDecoration get getChatStateDecoration {
    return ChatStateDecoration(
        message:
            message ?? xmpp.MessageStanza('', xmpp.MessageStanzaType.NONE));
  }

  Map<String, dynamic>? get getCustomData {
    if (message!.getCustom() != null) {
      return _tryParseCustomData(message!.getCustom()!.textValue!);
    }
    return {};
  }

  Map<String, dynamic> _tryParseCustomData(_customData) {
    final String customData = _customData;
    if (customData.isNotEmpty) {
      final firstAttempt = json.decode(customData);
      if (firstAttempt is String) {
        return Map<String, dynamic>.from(json.decode(firstAttempt));
      } else {
        return Map<String, dynamic>.from(firstAttempt);
      }
    }

    return const {};
  }
}
