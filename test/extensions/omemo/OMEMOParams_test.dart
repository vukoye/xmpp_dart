import 'package:test/test.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

void main() {
  group('extensions/omemo/OMEMOParams.dart', () {
    test('Should create the set device xml correctly', () {
      final publishDeviceParams = OMEMOPublishDeviceParams(
          accessModel: BundleAccessModel.open,
          itemId: 'current',
          devices: [
            OMEMODeviceInfo(deviceId: '1', deviceLabel: 'Nokia'),
            OMEMODeviceInfo(deviceId: '2', deviceLabel: '')
          ]);
      final iqElement = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('alice@capulet.lit'));
      print(iqElement.getChild('pubsub')!.buildXmlString());
      expect(iqElement.getAttribute('from')!.value, 'alice@capulet.lit');
      expect(iqElement.name, 'iq');
      expect(iqElement.getAttribute('type')!.value, 'set');
      expect(iqElement.getChild('pubsub')!.buildXmlString(),
          """<pubsub xmlns="http://jabber.org/protocol/pubsub">
  <publish node="urn:xmpp:omemo:2:devices">
    <item id="current">
      <devices xmlns="urn:xmpp:omemo:2">
        <device id="1" label="Nokia"/>
        <device id="2"/>
      </devices>
    </item>
  </publish>
  <publish-options>
    <x xmlns="jabber:x:data" type="submit">
      <field var="FORM_TYPE" type="hidden">
        <value>http://jabber.org/protocol/pubsub#publish-options</value>
      </field>
      <field var="pubsub#access_model">
        <value>open</value>
      </field>
    </x>
  </publish-options>
</pubsub>""");
    });
    test('Should create the get device xml correctly', () {
      final publishDeviceParams =
          OMEMOGetDevicesParams(buddyJid: Jid.fromFullJid('alice@capulet.lit'));
      final iqElement = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(iqElement.getChild('pubsub')!.buildXmlString());
      expect(iqElement.name, 'iq');
      expect(iqElement.getAttribute('type')!.value, 'get');
      expect(iqElement.getAttribute('from')!.value, 'bob@capulet.lit');
      expect(iqElement.getAttribute('to')!.value, 'alice@capulet.lit');
      expect(iqElement.getChild('pubsub')!.buildXmlString(),
          """<pubsub xmlns="http://jabber.org/protocol/pubsub">
  <items node="urn:xmpp:omemo:2:devices"/>
</pubsub>""");
    });
    test('Should create the get device\'s bundle xml correctly', () {
      final publishDeviceParams = OMEMOGetBundleParams(
          buddyJid: Jid.fromFullJid('alice@capulet.lit'),
          deviceIds: ['1', '2']);
      final iqElement = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(iqElement.getChild('pubsub')!.buildXmlString());
      expect(iqElement.name, 'iq');
      expect(iqElement.getAttribute('type')!.value, 'get');
      expect(iqElement.getAttribute('from')!.value, 'bob@capulet.lit');
      expect(iqElement.getAttribute('to')!.value, 'alice@capulet.lit');
      expect(iqElement.getChild('pubsub')!.buildXmlString(),
          """<pubsub xmlns="http://jabber.org/protocol/pubsub">
  <items node="urn:xmpp:omemo:2:bundles">
    <item id="1"/>
    <item id="2"/>
  </items>
</pubsub>""");
    });
    test('Should create the publish bundle xml correctly', () {
      final publishBundleParams = OMEMOPublishBundleParams(
          deviceId: '314566',
          ik: 'encodedIdentityKey',
          preKeys: [OMEMOPreKeyParams(id: '1', pk: 'encodedKey1')],
          spk: OMEMOPreKeyParams(id: '1', pk: 'encodedSignedPrekey'),
          spks: 'encodedSignature');

      final iqElement = publishBundleParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      expect(iqElement.name, 'iq');
      expect(iqElement.getAttribute('type')!.value, 'set');
      expect(iqElement.getAttribute('from')!.value, 'bob@capulet.lit');
      expect(iqElement.getChild('pubsub')!.buildXmlString(),
          """<pubsub xmlns="http://jabber.org/protocol/pubsub">
  <publish node="urn:xmpp:omemo:2:bundles">
    <item id="314566">
      <bundle xmlns="urn:xmpp:omemo:2">
        <spk id="1">encodedSignedPrekey</spk>
        <spks>encodedSignature</spks>
        <ik>encodedIdentityKey</ik>
        <prekeys>
          <pk id="1">encodedKey1</pk>
        </prekeys>
      </bundle>
    </item>
  </publish>
</pubsub>""");
    });
    test('Should create the plaintext envelope', () {
      final publishDeviceParams = OMEMOEnvelopePlainTextParams(
          plainText: 'Hello World', rpad: 'aa', time: '', customString: '');
      final envelope = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(envelope.buildXmlString());
      expect(envelope.name, 'envelope');
      expect(envelope.buildXmlString(), """<envelope xmlns="urn:xmpp:sce:1">
  <content>
    <body xmlns="jabber:client">Hello World</body>
  </content>
  <rpad>aa</rpad>
  <from jid="bob@capulet.lit"/>
</envelope>""");
    });
    test('Should create the plaintext envelope with time', () {
      final publishDeviceParams = OMEMOEnvelopePlainTextParams(
          plainText: 'Hello World',
          rpad: 'aa',
          time: DateTime(2022, 2, 2, 10, 10, 10, 10)
              .toUtc()
              .millisecondsSinceEpoch
              .toString(),
          customString: '');
      final envelope = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(envelope.buildXmlString());
      expect(envelope.name, 'envelope');
      expect(envelope.buildXmlString(), """<envelope xmlns="urn:xmpp:sce:1">
  <content>
    <TIME xmlns="urn:xmpp:time">
      <ts>1643771410010</ts>
    </TIME>
    <body xmlns="jabber:client">Hello World</body>
  </content>
  <rpad>aa</rpad>
  <from jid="bob@capulet.lit"/>
</envelope>""");
    });
    test('Should create the plaintext envelope with custom string', () {
      final publishDeviceParams = OMEMOEnvelopePlainTextParams(
          plainText: 'Hello World',
          rpad: 'aa',
          time: DateTime(2022, 2, 2, 10, 10, 10, 10)
              .toUtc()
              .millisecondsSinceEpoch
              .toString(),
          customString: '{"type": 1}');
      final envelope = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(envelope.buildXmlString());
      expect(envelope.name, 'envelope');
      expect(envelope.buildXmlString(), """<envelope xmlns="urn:xmpp:sce:1">
  <content>
    <TIME xmlns="urn:xmpp:time">
      <ts>1643771410010</ts>
    </TIME>
    <CUSTOM xmlns="urn:xmpp:custom">
      <custom>{"type": 1}</custom>
    </CUSTOM>
    <body xmlns="jabber:client">Hello World</body>
  </content>
  <rpad>aa</rpad>
  <from jid="bob@capulet.lit"/>
</envelope>""");
    });
    test('Should create the encrypted message for one to one chat', () {
      final publishDeviceParams = OMEMOEnvelopeEncryptionParams(
        senderDeviceId: '789',
        recipientInfo: [
          OMEMORecipientInfo(
              recipientJid: Jid.fromFullJid('alice@capulet.lit'),
              recipientKeysInfo: [
                OMEMORecipientDeviceInfo(
                    deviceId: '1', encoded: 'encoded-1', keyExchange: false),
                OMEMORecipientDeviceInfo(
                    deviceId: '2', encoded: 'encoded-2', keyExchange: true)
              ]),
          OMEMORecipientInfo(
              recipientJid: Jid.fromFullJid('bob@capulet.lit'),
              recipientKeysInfo: [
                OMEMORecipientDeviceInfo(
                    deviceId: '345', encoded: 'encoded-0', keyExchange: false)
              ])
        ],
        cipherText: 'Encryped Hello World',
      );
      final encrypted = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(encrypted.buildXmlString());
      expect(encrypted.name, 'encrypted');
      expect(encrypted.buildXmlString(), """<encrypted xmlns="urn:xmpp:omemo:2">
  <header sid="789">
    <keys jid="alice@capulet.lit">
      <key rid="1">encoded-1</key>
      <key rid="2" kex="true">encoded-2</key>
    </keys>
    <keys jid="bob@capulet.lit">
      <key rid="345">encoded-0</key>
    </keys>
  </header>
  <payload>Encryped Hello World</payload>
</encrypted>""");
    });
    test('Should create the encrypted message for group chat', () {
      final publishDeviceParams = OMEMOEnvelopeEncryptionParams(
        senderDeviceId: '789',
        recipientInfo: [
          OMEMORecipientInfo(
              recipientJid: Jid.fromFullJid('alice@capulet.lit'),
              recipientKeysInfo: [
                OMEMORecipientDeviceInfo(
                    deviceId: '1', encoded: 'encoded-1', keyExchange: false),
                OMEMORecipientDeviceInfo(
                    deviceId: '2', encoded: 'encoded-2', keyExchange: true)
              ]),
          OMEMORecipientInfo(
              recipientJid: Jid.fromFullJid('tom@capulet.lit'),
              recipientKeysInfo: [
                OMEMORecipientDeviceInfo(
                    deviceId: '5', encoded: 'encoded-5', keyExchange: true),
                OMEMORecipientDeviceInfo(
                    deviceId: '6', encoded: 'encoded-6', keyExchange: true)
              ]),
          OMEMORecipientInfo(
              recipientJid: Jid.fromFullJid('bob@capulet.lit'),
              recipientKeysInfo: [
                OMEMORecipientDeviceInfo(
                    deviceId: '345', encoded: 'encoded-0', keyExchange: false)
              ])
        ],
        cipherText: 'Encryped Hello World',
      );
      final encrypted = publishDeviceParams.buildRequest(
          from: Jid.fromFullJid('bob@capulet.lit'));
      print(encrypted.buildXmlString());
      expect(encrypted.name, 'encrypted');
      expect(encrypted.buildXmlString(), """<encrypted xmlns="urn:xmpp:omemo:2">
  <header sid="789">
    <keys jid="alice@capulet.lit">
      <key rid="1">encoded-1</key>
      <key rid="2" kex="true">encoded-2</key>
    </keys>
    <keys jid="tom@capulet.lit">
      <key rid="5" kex="true">encoded-5</key>
      <key rid="6" kex="true">encoded-6</key>
    </keys>
    <keys jid="bob@capulet.lit">
      <key rid="345">encoded-0</key>
    </keys>
  </header>
  <payload>Encryped Hello World</payload>
</encrypted>""");
    });

    test('Should create fetch bundle params xml correctly', () {
      const from = 'fromJid@shakespere.lit';
      const to = 'toJid@shakespere.lit';
      const id = 'someId';
      const itemId = 'someOtherId';

      final params = OMEMOFetchBundleParams(
          id: id, itemId: itemId, to: Jid.fromFullJid(to));

      final actual =
          params.buildRequest(from: Jid.fromFullJid(from)).buildXmlString();

      const expected = '<iq id="$id" type="get" from="$from" to="$to">\n' +
          '  <pubsub xmlns="http://jabber.org/protocol/pubsub">\n' +
          '    <items node="urn:xmpp:omemo:2:bundles">\n' +
          '      <item id="$itemId"/>\n' +
          '    </items>\n' +
          '  </pubsub>\n' +
          '</iq>';

      expect(actual, expected);
    });
  });
}
