import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptHeaderElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeyElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptKeysElement.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptPayloadElement.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';

class EncryptElement extends XmppElement {
  static String elementName = 'encrypted';
  EncryptElement() {
    name = elementName;
  }

  EncryptElement.build({
    required EncryptHeaderElement header,
    required EncryptPayloadElement payload,
  }) {
    name = EncryptElement.elementName;
    addAttribute(XmppAttribute('xmlns', 'urn:xmpp:omemo:2'));
    addChild(header);
    addChild(payload);
  }
  /* 
<message id="ac0fdeb0-93ce-11ec-a6de-198322437fd4" type="chat" to="627075027401@staging.xmpp.hiapp-chat.com" from="627775027401@staging.xmpp.hiapp-chat.com/Android-9bbd97e55c84849a-2a4866b1-1a67-4377-9367-50e9111a80d7">
        <encrypted xmlns="urn:xmpp:omemo:2">
          <header sid="9bbd97e55c84849a">
            <keys jid="627075027401@staging.xmpp.hiapp-chat.com">
              <key rid="96F42D78-D7E7-4DFD-ADE8-4A08CE64836D" kex="true">Mwi9YxABGiApYztg3BqMvJhYG0+g9XooxYoPSmLyKYdpjFILoBAQDiIg7E0hQWjFnmpn6VKQVwLILGK6LkQm6ohGz6JzfgtGvlEqggMzCAAQABogrmdT3ichMTqyV3ypaBHnp3/EjEsHp/RlKkhaWdFOZwMi0AIewOMkYcEiKUhUKCZAhkHOovfU37VSNfbZpUQb0lmuFNoH3F9cwbquAMmnL2VKiu2p06Ajk6Ejg6ykX9N446kP89vVcSBSA5rHgUca0i7PM1907pMf/TIh9HbcQ5Sq1IevFnIBJNctjCKEph290qV9zpHtLc+YUj2dhBpfeJLkjmMIWiRXFvWqjxXTefHHt6ENKMyNaCUer2vPKgBDeBrzM4lcTOZ1dFyfafd6jOzcuc/aXlt9qUXf9+DJRbX0cA1i0Gu68TkCL09Uw8tg6990cJkgkYZp5SXyZ28w7KOfoJFdwltTXW2VeYmk5RyEM/rq/OhSiJbGd0VOX6alt8jN6JcCOyxufE21hSX6An2Fg/ufowROPAtuBOm1wqTCAyH4HkTO3plQgokr2AC3Jjr4f7KBoqMyVFKgcdUfcAdYYIfu+CiEFlGbs1N3yB12VjImcpkrtnQPHzIgDJzArQt3jq8ut1hylJrxFJ1Qc0jt05pXTUME12bHBJk=</key>
            </keys>
          </header>
          <payload></payload>
        </encrypted>
        <request xmlns="urn:xmpp:receipts"/>
      </message>

  */
  static Tuple2<XmppElement, OMEMOEnvelopeEncryptionParams>? parseEncryption(
      parent) {
    try {
      final _encryptElement = parent.children.firstWhere(
          (child) => (child.name == EncryptElement.elementName),
          orElse: () => null);
      if (_encryptElement == null) {
        return null;
      }
      final _headerElement = EncryptHeaderElement.parse(_encryptElement);

      if (_headerElement == null) {
        return null;
      }
      final _payloadElement = EncryptPayloadElement.parse(_encryptElement);

      final keysElement = _headerElement.children
          .where((element) => element!.name == EncryptKeysElement.elementName);
      final List<EncryptKeysElement> keysList = [];

      final List<OMEMORecipientInfo> recipientInfo = [];

      keysElement.forEach((keys) {
        List<EncryptKeyElement> keyList = [];
        List<OMEMORecipientDeviceInfo> recipientKeysInfo = [];
        keys!.children
            .where((element) => element!.name == EncryptKeyElement.elementName)
            .forEach((key) {
          final deviceId = key!.getAttribute('rid')!.value!;
          final isKeyExchange = key.getAttribute('kex') != null &&
              key.getAttribute('kex')!.value! == 'true';
          final encoded = key.textValue!;
          keyList.add(EncryptKeyElement.build(
              rid: deviceId, keyExchange: isKeyExchange, encoded: encoded));

          recipientKeysInfo.add(OMEMORecipientDeviceInfo(
              deviceId: deviceId,
              keyExchange: isKeyExchange,
              encoded: encoded));
        });
        final recipient = Jid.fromFullJid(keys.getAttribute('jid')!.value!);
        keysList.add(
            EncryptKeysElement.build(to: recipient, recipientKeys: keyList));

        recipientInfo.add(OMEMORecipientInfo(
            recipientJid: recipient, recipientKeysInfo: recipientKeysInfo));
      });
      final senderDeviceId = _headerElement.getAttribute('sid')!.value!;
      final cipherPayload =
          _payloadElement!.textValue == null ? '' : _payloadElement.textValue!;
      final EncryptHeaderElement header = EncryptHeaderElement.build(
          senderDeviceId: senderDeviceId, recipientKeysList: keysList);
      final EncryptElement encryptElement = EncryptElement.build(
        header: header,
        payload: EncryptPayloadElement.build(cipherText: cipherPayload),
      );

      final OMEMOEnvelopeEncryptionParams params =
          OMEMOEnvelopeEncryptionParams(
              cipherText: cipherPayload,
              recipientInfo: recipientInfo,
              senderDeviceId: senderDeviceId);

      return Tuple2<XmppElement, OMEMOEnvelopeEncryptionParams>(
          encryptElement, params);
    } catch (e) {
      return null;
    }
  }

  static XmppElement? parseElement(parent) {
    try {
      return parseEncryption(parent)!.item1;
    } catch (e) {
      return null;
    }
  }

  static OMEMOEnvelopeEncryptionParams? parseParams(parent) {
    try {
      return parseEncryption(parent)!.item2;
    } catch (e) {
      return null;
    }
  }
}
