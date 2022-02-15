import 'package:xml/xml.dart';
import 'package:test/test.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/response/base_response.dart';

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
   <iq from='coven@chat.shakespeare.lit' id='config1' to='crone1@shakespeare.lit/desktop' type='result'> <query xmlns='http://jabber.org/protocol/muc#owner'> <x xmlns='jabber:x:data' type='form'> <title>Configuration for "coven" Room</title> <instructions> Complete this form to modify the configuration of your room. </instructions> <field type='hidden' var='FORM_TYPE'> <value>http://jabber.org/protocol/muc#roomconfig</value> </field> <field label='Natural-Language Room Name' type='text-single' var='muc#roomconfig_roomname'> <value>A Dark Cave</value> </field> <field label='Short Description of Room' type='text-single' var='muc#roomconfig_roomdesc'> <value>The place for all good witches!</value> </field> <field label='Enable Public Logging?' type='boolean' var='muc#roomconfig_enablelogging'> <value>0</value> </field> <field label='Allow Occupants to Change Subject?' type='boolean' var='muc#roomconfig_changesubject'> <value>0</value> </field> <field label='Allow Occupants to Invite Others?' type='boolean' var='muc#roomconfig_allowinvites'> <value>0</value> </field> <field label='Who Can Send Private Messages?' type='list-single' var='muc#roomconfig_allowpm'> <value>anyone</value> <option label='Anyone'> <value>anyone</value> </option> <option label='Anyone with Voice'> <value>participants</value> </option> <option label='Moderators Only'> <value>moderators</value> </option> <option label='Nobody'> <value>none</value> </option> </field> <field label='Maximum Number of Occupants' type='list-single' var='muc#roomconfig_maxusers'> <value>10</value> <option label='10'><value>10</value></option> <option label='20'><value>20</value></option> <option label='30'><value>30</value></option> <option label='50'><value>50</value></option> <option label='100'><value>100</value></option> <option label='None'><value>none</value></option> </field> <field label='Roles for which Presence is Broadcasted' type='list-multi' var='muc#roomconfig_presencebroadcast'> <value>moderator</value> <value>participant</value> <value>visitor</value> <option label='Moderator'><value>moderator</value></option> <option label='Participant'><value>participant</value></option> <option label='Visitor'><value>visitor</value></option> </field> <field label='Roles and Affiliations that May Retrieve Member List' type='list-multi' var='muc#roomconfig_getmemberlist'> <value>moderator</value> <value>participant</value> <value>visitor</value> <option label='Moderator'><value>moderator</value></option> <option label='Participant'><value>participant</value></option> <option label='Visitor'><value>visitor</value></option> </field> <field label='Make Room Publicly Searchable?' type='boolean' var='muc#roomconfig_publicroom'> <value>0</value> </field> <field label='Make Room Persistent?' type='boolean' var='muc#roomconfig_persistentroom'> <value>0</value> </field> <field label='Make Room Moderated?' type='boolean' var='muc#roomconfig_moderatedroom'> <value>0</value> </field> <field label='Make Room Members Only?' type='boolean' var='muc#roomconfig_membersonly'> <value>0</value> </field> <field label='Password Required for Entry?' type='boolean' var='muc#roomconfig_passwordprotectedroom'> <value>1</value> </field> <field type='fixed'> <value> If a password is required to enter this room, you must specify the password below. </value> </field> <field label='Password' type='text-private' var='muc#roomconfig_roomsecret'> <value>cauldronburn</value> </field> <field label='Who May Discover Real JIDs?' type='list-single' var='muc#roomconfig_whois'> <value>moderators</value> <option label='Moderators Only'> <value>moderators</value> </option> <option label='Anyone'> <value>anyone</value> </option> </field> <field label='Maximum Number of History Messages Returned by Room' type='text-single' var='muc#maxhistoryfetch'> <value>50</value> </field> <field type='fixed'> <value> You may specify additional people who have admin status in the room. Please provide one Jabber ID per line. </value> </field> <field label='Room Admins' type='jid-multi' var='muc#roomconfig_roomadmins'> <value>wiccarocks@shakespeare.lit</value> <value>hecate@shakespeare.lit</value> </field> <field type='fixed'> <value> You may specify additional owners for this room. Please provide one Jabber ID per line. </value> </field> <field label='Room Owners' type='jid-multi' var='muc#roomconfig_roomowners'/> </x> </query> </iq>
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
