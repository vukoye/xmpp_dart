import 'package:xml/xml.dart';
import 'package:test/test.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

void main() {
  // TODO: add more case, for now, one happy case, to add more
  group('extensions/omemo/MultiUserChatData.dart', () {
    test('Should parse the get member successfully', () {
      final xmlDoc = XmlDocument.parse("""
   <iq from='coven@chat.shakespeare.lit'
    id='member3'
    to='crone1@shakespeare.lit/desktop'
    type='result'>
  <query xmlns='http://jabber.org/protocol/muc#admin'>
    <item affiliation='member'
          jid='hag66@shakespeare.lit'
          nick='thirdwitch'
          role='participant'/>
  </query>
</iq>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = GetUsersResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.users.isNotEmpty, true);
      expect(response.users.first.userAtDomain, 'hag66@shakespeare.lit');
    });
    test('Should parse the join room response successfully', () {
      final xmlDoc = XmlDocument.parse("""
   <presence
    from='coven@chat.shakespeare.lit/firstwitch'
    to='crone1@shakespeare.lit/desktop'>
  <x xmlns='http://jabber.org/protocol/muc#user'>
    <item affiliation='owner'
          role='moderator'/>
    <status code='110'/>
    <status code='201'/>
  </x>
</presence>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = JoinRoomResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.success, true);
    });
    test('Should parse the get room config response successfully', () {
      final xmlDoc = XmlDocument.parse("""
   <iq from="test2b3626e00-7789-11ec-b82f-6dc971962c7e@conference.dev.xmpp.hiapp-chat.com" to="621271021001@dev.xmpp.hiapp-chat.com/iOS-D9BDC54B-0B61-410B-8FBB-633B3196A8C7-cb8cf018-5195-47fd-9785-3ab33511a6ab" id="HJPLWRKPU" type="result"> <query xmlns="http://jabber.org/protocol/muc#owner"> <instructions>You need an x:data capable client to configure room</instructions> <x xmlns="jabber:x:data" type="form"> <title>Configuration of room test2b3626e00-7789-11ec-b82f-6dc971962c7e@conference.dev.xmpp.hiapp-chat.com</title> <field type="hidden" var="FORM_TYPE"> <value>http://jabber.org/protocol/muc#roomconfig</value> </field> <field type="text-single" label="Room title" var="muc#roomconfig_roomname"> <value /> </field> <field type="text-single" label="Room description" var="muc#roomconfig_roomdesc"> <value /> </field> <field type="boolean" label="Make room persistent" var="muc#roomconfig_persistentroom"> <value>0</value> </field> <field type="boolean" label="Make room public searchable" var="muc#roomconfig_publicroom"> <value>1</value> </field> <field type="boolean" label="Make participants list public" var="public_list"> <value>1</value> </field> <field type="boolean" label="Make room password protected" var="muc#roomconfig_passwordprotectedroom"> <value>0</value> </field> <field type="text-private" label="Password" var="muc#roomconfig_roomsecret"> <value /> </field> <field type="list-multi" label="Roles and affiliations that may retrieve member list" var="muc#roomconfig_getmemberlist"> <value>moderator</value> <value>participant</value> <value>visitor</value> <option label="moderator"> <value>moderator</value> </option> <option label="participant"> <value>participant</value> </option> <option label="visitor"> <value>visitor</value> </option> </field> <field type="list-single" label="Maximum Number of Occupants" var="muc#roomconfig_maxusers"> <value>200</value> <option label="5"> <value>5</value> </option> <option label="10"> <value>10</value> </option> <option label="20"> <value>20</value> </option> <option label="30"> <value>30</value> </option> <option label="50"> <value>50</value> </option> <option label="100"> <value>100</value> </option> <option label="200"> <value>200</value> </option> <option label="300"> <value>300</value> </option> </field> <field type="list-single" label="Present real Jabber IDs to" var="muc#roomconfig_whois"> <value>moderators</value> <option label="moderators only"> <value>moderators</value> </option> <option label="anyone"> <value>anyone</value> </option> </field> <field type="boolean" label="Make room members-only" var="muc#roomconfig_membersonly"> <value>0</value> </field> <field type="boolean" label="Make room moderated" var="muc#roomconfig_moderatedroom"> <value>1</value> </field> <field type="boolean" label="Default users as participants" var="members_by_default"> <value>1</value> </field> <field type="boolean" label="Allow users to change the subject" var="muc#roomconfig_changesubject"> <value>1</value> </field> <field type="boolean" label="Allow users to send private messages" var="allow_private_messages"> <value>1</value> </field> <field type="boolean" label="Allow users to query other users" var="allow_query_users"> <value>1</value> </field> <field type="boolean" label="Allow users to send invites" var="muc#roomconfig_allowinvites"> <value>0</value> </field> <field type="boolean" label="Allow users to enter room with multiple sessions" var="muc#roomconfig_allowmultisessions"> <value>1</value> </field> <field type="boolean" label="Allow visitors to send status text in presence updates" var="muc#roomconfig_allowvisitorstatus"> <value>1</value> </field> <field type="boolean" label="Allow visitors to change nickname" var="muc#roomconfig_allowvisitornickchange"> <value>1</value> </field> </x> </query> </iq>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = GetRoomConfigResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.success, true);
    });
    test(
        'Should parse the error trying to get room config response when room is not existed',
        () {
      final xmlDoc = XmlDocument.parse("""
   

   <iq from='tseting@conference.dev.xmpp.hiapp-chat.com' to='627775027401@dev.xmpp.hiapp-chat.com/c714d7b25ea373e31640-246580-77685' type='error' xml:lang='en' id='MVEPQWBJA'>
     <query xmlns='http://jabber.org/protocol/disco#info'/>
       <error code='404' type='cancel'>
         <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
         <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>Conference room does not exist</text>
       </error>
   </iq>

""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = GetRoomConfigResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseErrorResponse);
      expect(response.success, false);
      expect((response.response as BaseErrorResponse).code, '404');
      expect((response.response as BaseErrorResponse).message,
          'Conference room does not exist');
    });
    test('Should parse the set room config response successfully', () {
      final xmlDoc = XmlDocument.parse("""
  <iq from='coven@chat.shakespeare.lit'
    id='create2'
    to='crone1@shakespeare.lit/desktop'
    type='result'/>
""");
      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final response = SetRoomConfigResponse.parse(stanza!);
      expect(response.response.runtimeType, BaseValidResponse);
      expect(response.success, true);
    });
  });
}
