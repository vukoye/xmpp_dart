import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/bundles/BundleElement.dart';
import 'package:xmpp_stone/src/elements/bundles/IKElement.dart';
import 'package:xmpp_stone/src/elements/bundles/PKElement.dart';
import 'package:xmpp_stone/src/elements/bundles/PreKeysElement.dart';
import 'package:xmpp_stone/src/elements/bundles/SPKElement.dart';
import 'package:xmpp_stone/src/elements/bundles/SPKSElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptHeaderElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeyElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeysElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptPayloadElement.dart';
import 'package:xmpp_stone/src/elements/encryption/PlainEnvelope.dart';
import 'package:xmpp_stone/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomSubElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeStampElement.dart';
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
  buildRequest({required Jid from});
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
  final String itemId;
  final BundleAccessModel accessModel;

  const OMEMOPublishDeviceParams(
      {required this.devices, required this.itemId, required this.accessModel});

  @override
  IqStanza buildRequest({required Jid from}) {
    final iqElement = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqElement.fromJid = from;
    final pubsubElement = PubSubElement.build();
    final publishElement = PublishElement.build('urn:xmpp:omemo:2:devices');
    final itemElement = ItemElement.build(itemId);
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

class OMEMOPreKeyParams {
  final String id;
  // as hex
  final String pk;

  const OMEMOPreKeyParams({required this.id, required this.pk});
}

class OMEMOPublishBundleParams extends OMEMOParams {
  final String deviceId;
  final OMEMOPreKeyParams spk;
  // In hex
  final String spks;
  // In hex
  final String ik;
  final List<OMEMOPreKeyParams> preKeys;

  const OMEMOPublishBundleParams(
      {required this.deviceId,
      required this.spk,
      required this.spks,
      required this.ik,
      required this.preKeys});

  @override
  IqStanza buildRequest({required Jid from}) {
    final iqElement = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    final pubsub = PubSubElement.build();
    final publish = PublishElement.buildOMEMOBundle();
    final item = ItemElement.build(deviceId);
    final bundle = BundleElement.buildOMEMOBundle();
    final spkElement = SPKElement.build(id: spk.id, encodedData: spk.pk);
    final spksElement = SPKSElement.build(encodedData: spks);
    final ikElement = IKElement.build(encodedData: ik);
    final List<PKElement> pkList = [];
    preKeys.forEach((element) {
      pkList.add(PKElement.build(id: element.id, encodedData: element.pk));
    });
    bundle.addChild(spkElement);
    bundle.addChild(spksElement);
    bundle.addChild(ikElement);
    bundle.addChild(PreKeysElement.build(pkElements: pkList));
    item.addChild(bundle);
    publish.addChild(item);
    pubsub.addChild(publish);

    iqElement.fromJid = from;
    iqElement.addChild(pubsub);
    return iqElement;
  }
  // final Iterable<OMEMODeviceInfo> devices;
  // final String bundleId;
}

class OMEMOFetchBundleParams extends OMEMOParams {
  final Jid to;
  final String id;
  final String itemId;

  const OMEMOFetchBundleParams({
    required this.id,
    required this.to,
    required this.itemId,
  });

  @override
  IqStanza buildRequest({required Jid from}) {
    IqStanza stanza = IqStanza(id, IqStanzaType.GET)
      ..addAttribute(XmppAttribute('from', from.fullJid))
      ..addAttribute(XmppAttribute('to', to.fullJid))
      ..addChild(XmppElement()
        ..name = 'pubsub'
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/pubsub'))
        ..addChild(XmppElement()
          ..name = 'items'
          ..addAttribute(XmppAttribute('node', 'urn:xmpp:omemo:2:bundles'))
          ..addChild(XmppElement()
            ..name = 'item'
            ..addAttribute(XmppAttribute('id', itemId)))));

    return stanza;
  }
}

class OMEMOGetDevicesParams extends OMEMOParams {
  final Jid buddyJid;

  const OMEMOGetDevicesParams({required this.buddyJid});

  @override
  IqStanza buildRequest({required Jid from}) {
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
  IqStanza buildRequest({required Jid from}) {
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
  final String time;
  final String customString;

  const OMEMOEnvelopePlainTextParams(
      {required this.plainText,
      required this.rpad,
      required this.time,
      required this.customString});
  @override
  XmppElement buildRequest({required Jid from}) {
    final envelope = PlainEnvelope.build(
        xmlns: 'urn:xmpp:sce:1',
        plainText: plainText,
        rpad: rpad,
        from: from,
        time: time,
        customString: customString);
    return envelope;
  }
}

class OMEMOEnvelopeParsePlainTextParams extends OMEMOParams {
  final String elementXml;

  const OMEMOEnvelopeParsePlainTextParams({
    required this.elementXml,
  });
  @override
  XmppElement buildRequest({required Jid from}) {
    return XmppElement();
  }
}

class OMEMOEnvelopeEncryptionParams extends OMEMOParams {
  final String senderDeviceId;
  final Iterable<OMEMORecipientInfo> recipientInfo;
  final String cipherText;

  const OMEMOEnvelopeEncryptionParams(
      {required this.senderDeviceId,
      required this.recipientInfo,
      required this.cipherText});

  @override
  EncryptElement buildRequest({required Jid from}) {
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
    return EncryptElement.build(
      header: headerElement,
      payload: EncryptPayloadElement.build(cipherText: cipherText),
    );
  }
}


// class OMEMOEnvelopeEncryptionContentParams extends OMEMOParams {
//   final Jid to;
//   final String payload;

//   const OMEMOEnvelopeEncryptionContentParams({required this.to, required this.payload});

//   @override
//   buildRequest({required Jid from}) {
//     final stanza = MessageStanza(null, MessageStanzaType.NONE);
//     stanza.toJid = to;
//     stanza.fromJid = from;
    
//     XmppElement encryptedElement = XmppElement('encrypted')..addAttribute(XmppAttribute('xmlns', 'urn:xmpp:encryption:stub:sce:1'));
//     XmppElement payloadElement = XmppElement('payload')..textValue = payload;
//     encryptedElement.addChild(payloadElement);
//     stanza.children.add(encryptedElement);
    
//     return stanza;
//   }

// }
