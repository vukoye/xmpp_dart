import 'package:xml/xml.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:test/test.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

void main() {
  // TODO: add more case, for now, one happy case, to add more
  group('extensions/omemo/OMEMOData.dart', () {
    test('Should parse success response from publish device list successfully',
        () {
      final xmlDoc = XmlDocument.parse("""
    <iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-cdbf4a3a-04ec-413e-841e-03e2490c3d87' id='AQCVFXQRG' type='result'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <publish node='urn:xmpp:omemo:2:devices'>
          <item id='current'/>
        </publish>
      </pubsub>
    </iq>

""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = OMEMOPublishDeviceResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.deviceStoreItemId, 'current');
    });

    test('Should parse success response from get device list successfully', () {
      final xmlDoc = XmlDocument.parse("""
    <iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-96f6a2d3-69fc-4aa4-a0af-6964433055f5' id='VFRSFCMSU' type='result'>
     <pubsub xmlns='http://jabber.org/protocol/pubsub'>
       <items node='urn:xmpp:omemo:2:devices'>
         <item id='current'>
           <devices xmlns='urn:xmpp:omemo:2'>
             <device id='f42af6e50523a5f8' label='Current'/>
           </devices>
         </item>
       </items>
     </pubsub>
   </iq>

""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = OMEMOGetDevicesResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.devices.isNotEmpty, true);
      expect(response.devices.first.deviceId, 'f42af6e50523a5f8');
      expect(response.devices.first.deviceLabel, 'Current');
    });
    test('Should parse error response from get device list successfully', () {
      final xmlDoc = XmlDocument.parse("""
      <iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-657e41c8-2225-4ca2-8650-b609084e3256' id='JKHXCJXOH' type='error'>
        <error code='404' type='cancel'><item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
       </error>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <items node='urn:xmpp:omemo:2:devices'/>
        </pubsub>
      </iq>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = OMEMOGetDevicesResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseErrorResponse);
      expect((response.response as BaseErrorResponse).code, '404');
      expect(
          (response.response as BaseErrorResponse).message, 'Item not found');
    });
    test('Should parse success response from publish bundle successfully', () {
      final xmlDoc = XmlDocument.parse("""
    <iq from='627075827401@dev2.xmpp.hiapp-chat.com' to='627075827401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-a556406d-1756-446d-be30-973895f83314' id='JHRVSASTL' type='result'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <publish node='urn:xmpp:omemo:2:bundles'>
          <item id='f42af6e50523a5f8'/>
        </publish>
      </pubsub>
    </iq>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = OMEMOPublishBundleResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.success, true);
      expect(response.deviceId, 'f42af6e50523a5f8');
    });
  });

  test('Should parse envelope from encrypt xml', () {
    final xmlDoc = XmlDocument.parse("""<message>
        <envelope xmlns="urn:xmpp:sce:1">
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
  </envelope>
</message>""");
    final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
    final value = OMEMOEnvelopePlainTextParseResponse.parse(stanza);
    expect(value.body, 'Hello World');
    expect(value.customString, '{"type": 1}');
    expect(value.time, '1643771410010');
    expect(value.rpad, 'aa');
    expect(value.from, 'bob@capulet.lit');
  });
}
