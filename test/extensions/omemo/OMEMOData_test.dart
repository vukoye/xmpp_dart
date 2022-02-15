import 'package:xml/xml.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:test/test.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

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
      expect(response.response.runtimeType, OMEMOValidResponse);
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
      expect(response.response.runtimeType, OMEMOValidResponse);
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
      expect(response.response.runtimeType, OMEMOErrorResponse);
      expect((response.response as OMEMOErrorResponse).code, '404');
      expect(
          (response.response as OMEMOErrorResponse).message, 'Item not found');
    });
  });
}
