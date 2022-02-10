import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';
import 'package:test/test.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

void main() {
  group('extensions/omemo/OMEMOParams.dart', () {
    test('Should create the set device xml correctly', () {
      final publishDeviceParams = OMEMOPublishDeviceParams(
          accessModel: BundleAccessModel.open,
          bundleId: 'current',
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
  });
}
