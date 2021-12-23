import 'dart:convert';

import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class XMPPMessageParams {
  final xmpp.MessageStanza message;
  const XMPPMessageParams({this.message});

  bool get isMessageCustom {
    return message.body == null && message.getCustom() != null;
  }

  bool get isMessage {
    return message.body != null && message.getCustom() == null;
  }

  bool get isOnlyMessage {
    return !(isAckDeliveryClient ||
        isAckDeliveryDirect ||
        isAckDeliveryStored ||
        isAckReadClient ||
        isDelay ||
        isCarbon);
  }

  bool get isRequestingReceipt {
    return message.getRequestReceipt() != null;
  }

  bool get isAckDeliveryDirect {
    return message.body == null && message.isAmpDeliverDirect();
  }

  bool get isAckDeliveryStored {
    return message.body == null && message.isAmpDeliverStore();
  }

  bool get isAckDeliveryClient {
    return (message.body == null &&
        message.getCustom() == null &&
        !message.isAmpDeliverStore() &&
        !message.isAmpDeliverDirect() &&
        message.fromJid.isValid() &&
        message.toJid.isValid());
  }

  bool get isAckReadClient {
    return (message.body == null &&
        message.getCustom() != null &&
        getCustomData['iqType'] == 'Read-Ack');
  }

  bool get isDelay {
    return message.getDelay() != null;
  }

  String get delayedMessageType {
    return message.getDelay() != null ? message.getDelay().textValue : 'N/A';
  }

  bool get isCarbon {
    return message.getSent() != null;
  }

  Map<String, dynamic> get getCustomData {
    if (isMessageCustom) {
      return json.decode(message.getCustom().textValue);
    }
    return {};
  }
}
