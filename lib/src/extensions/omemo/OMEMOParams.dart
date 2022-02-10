import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptHeaderElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeyElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeysElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptPayloadElement.dart';
import 'package:xmpp_stone/src/elements/encryption/PlainEnvelope.dart';
import 'package:xmpp_stone/src/elements/pubsub/ItemElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/ItemsElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/PubSubElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/PublishElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/PublishOptionsElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DeviceElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DevicesElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

abstract class OMEMOParams {
  XmppElement buildRequest({required Jid from});
  const OMEMOParams();
}

enum BundleAccessModel {
  open,
}

class OMEMODeviceInfo {
  final String deviceId;
  final String deviceLabel;

  const OMEMODeviceInfo({required this.deviceId, required this.deviceLabel});
}

class OMEMORecipientDeviceInfo {
  final String deviceId;
  final String encoded;
  final bool keyExchange;

  const OMEMORecipientDeviceInfo(
      {required this.deviceId,
      required this.encoded,
      required this.keyExchange});
}

class OMEMORecipientInfo {
  final Jid recipientJid;
  final Iterable<OMEMORecipientDeviceInfo> recipientKeysInfo;

  const OMEMORecipientInfo(
      {required this.recipientJid, required this.recipientKeysInfo});
}

class OMEMOPublishDeviceParams extends OMEMOParams {
  final Iterable<OMEMODeviceInfo> devices;
  final String bundleId;
  final BundleAccessModel accessModel;

  const OMEMOPublishDeviceParams(
      {required this.devices,
      required this.bundleId,
      required this.accessModel});

  @override
  XmppElement buildRequest({required Jid from}) {
    final iqElement = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqElement.fromJid = from;
    final pubsubElement = PubSubElement.build();
    final publishElement = PublishElement.build('urn:xmpp:omemo:2:devices');
    final itemElement = ItemElement.build(bundleId);
    final deviceList = devices.map<DeviceElement>(
        (e) => DeviceElement.build(id: e.deviceId, label: e.deviceLabel));
    final devicesElement = DevicesElement.build(deviceList.toList());
    itemElement.addChild(devicesElement);
    publishElement.addChild(itemElement);
    final publishOptions =
        PublishOptionsElement.build(accessModel: accessModel.name);
    pubsubElement.addChild(publishElement);
    pubsubElement.addChild(publishOptions);
    iqElement.addChild(pubsubElement);
    return iqElement;
  }
}

class OMEMOPublishBundleParams extends OMEMOParams {
  @override
  XmppElement buildRequest({required Jid from}) {
    // TODO: implement buildRequest
    throw UnimplementedError();
  }
  // final Iterable<OMEMODeviceInfo> devices;
  // final String bundleId;
}

class OMEMOGetDevicesParams extends OMEMOParams {
  final Jid buddyJid;

  const OMEMOGetDevicesParams({required this.buddyJid});

  @override
  XmppElement buildRequest({required Jid from}) {
    final iqElement = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqElement.fromJid = from;
    iqElement.toJid = buddyJid;
    final pubsubElement = PubSubElement.build();
    final items = ItemsElement.build('urn:xmpp:omemo:2:devices');
    pubsubElement.addChild(items);
    iqElement.addChild(pubsubElement);
    return iqElement;
  }
}

class OMEMOGetBundleParams extends OMEMOParams {
  final Jid buddyJid;
  final Iterable<String> deviceIds;

  const OMEMOGetBundleParams({required this.buddyJid, required this.deviceIds});
  @override
  XmppElement buildRequest({required Jid from}) {
    final iqElement = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqElement.fromJid = from;
    iqElement.toJid = buddyJid;
    final pubsubElement = PubSubElement.build();
    final items = ItemsElement.build('urn:xmpp:omemo:2:bundles');
    final itemList = deviceIds.map<ItemElement>((e) => ItemElement.build(e));
    itemList.forEach((item) {
      items.addChild(item);
    });

    pubsubElement.addChild(items);
    iqElement.addChild(pubsubElement);
    return iqElement;
  }
}

class OMEMOEnvelopePlainTextParams extends OMEMOParams {
  final String plainText;
  final String rpad;

  const OMEMOEnvelopePlainTextParams(
      {required this.plainText, required this.rpad});
  @override
  XmppElement buildRequest({required Jid from}) {
    final envelope = PlainEnvelope.build(
        xmlns: 'urn:xmpp:sce:1', plainText: plainText, rpad: rpad, from: from);
    return envelope;
  }
}

class OMEMOEnvelopeEncryptionParams extends OMEMOParams {
  final String messageId;
  final MessageStanzaType messageType;
  final String senderDeviceId;
  final Jid buddyJid;
  final Iterable<OMEMORecipientInfo> recipientInfo;
  final String cipherText;

  const OMEMOEnvelopeEncryptionParams(
      {required this.messageId,
      required this.messageType,
      required this.senderDeviceId,
      required this.buddyJid,
      required this.recipientInfo,
      required this.cipherText});

  @override
  XmppElement buildRequest({required Jid from}) {
    final message = MessageStanza(messageId, messageType);
    message.toJid = buddyJid;
    message.fromJid = from;
    List<EncryptKeysElement> recipientKeysList = [];
    recipientInfo.forEach((element) {
      List<EncryptKeyElement> recipientKeys = [];
      element.recipientKeysInfo.forEach((key) {
        recipientKeys.add(EncryptKeyElement.build(
            rid: key.deviceId,
            keyExchange: key.keyExchange,
            encoded: key.encoded));
      });
      recipientKeysList.add(EncryptKeysElement.build(
          to: element.recipientJid, recipientKeys: recipientKeys));
    });
    final headerElement = EncryptHeaderElement.build(
        senderDeviceId: senderDeviceId, recipientKeysList: recipientKeysList);
    message.addChild(EncryptElement.build(
        header: headerElement,
        payload: EncryptPayloadElement.build(cipherText: cipherText),
        encoded: cipherText));
    final store = XmppElement();
    store.name = 'store';
    store.addAttribute(XmppAttribute('xmlns', 'urn:xmpp:hints'));
    message.addChild(store);
    return message;
  }
}
