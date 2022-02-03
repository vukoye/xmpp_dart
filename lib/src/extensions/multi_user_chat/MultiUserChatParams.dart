import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';

class MultiUserChatCreateParams {
  final GroupChatroomParams config;
  final XmppCommunicationConfig options;
  const MultiUserChatCreateParams({
    required this.config,
    required this.options,
  });

  static MultiUserChatCreateParams build({
    GroupChatroomParams config = const GroupChatroomParams(
        name: '',
        description: '',
        enablelogging: false,
        changesubject: false,
        allowinvites: true,
        allowPm: false,
        maxUser: 20,
        presencebroadcast: ['moderator', 'participant', 'visitor'],
        getmemberlist: ['moderator', 'participant', 'visitor'],
        publicroom: false,
        persistentroom: true,
        membersonly: true,
        passwordprotectedroom: false),
    XmppCommunicationConfig options =
        const XmppCommunicationConfig(shallWaitStanza: false),
  }) {
    return MultiUserChatCreateParams(config: config, options: options);
  }
}

class MultiUserChatQueryParams {
  final XmppCommunicationConfig options;
  const MultiUserChatQueryParams({
    required this.options,
  });

  static MultiUserChatQueryParams build({
    XmppCommunicationConfig options =
        const XmppCommunicationConfig(shallWaitStanza: false),
  }) {
    return MultiUserChatQueryParams(options: options);
  }
}

class GroupChatroomParams {
  final String name;
  final String description;
  final bool enablelogging;
  final bool changesubject;
  final bool allowinvites;
  final bool allowPm;
  final int maxUser;
  final List<String> presencebroadcast;
  final List<String> getmemberlist;
  final bool publicroom;
  final bool persistentroom;
  final bool membersonly;
  final bool passwordprotectedroom;

  const GroupChatroomParams({
    required this.name,
    required this.description,
    required this.enablelogging,
    required this.changesubject,
    required this.allowinvites,
    required this.allowPm,
    required this.maxUser,
    required this.presencebroadcast,
    required this.getmemberlist,
    required this.publicroom,
    required this.persistentroom,
    required this.membersonly,
    required this.passwordprotectedroom,
  });

  static GroupChatroomParams build({
    required name,
    required description,
  }) {
    return GroupChatroomParams(
        name: name,
        description: description,
        enablelogging: false,
        changesubject: false,
        allowinvites: true,
        allowPm: true,
        maxUser: 20,
        presencebroadcast: ['moderator', 'participant', 'visitor'],
        getmemberlist: ['moderator', 'participant', 'visitor'],
        publicroom: false,
        persistentroom: true,
        membersonly: true,
        passwordprotectedroom: false);
  }
}

class GroupChatroomFormParams {
  final GroupChatroomParams config;
  const GroupChatroomFormParams({required this.config});

  XmppElement buildInstantRoom() {
    QueryElement query = QueryElement();
    query.setXmlns('http://jabber.org/protocol/muc#owner');
    XElement xElement = XElement.build();
    xElement.setType(FormType.SUBMIT);
    query.addChild(xElement);
    return query;
  }

  XmppElement buildForm() {
    QueryElement query = QueryElement();
    query.setXmlns('http://jabber.org/protocol/muc#owner');
    XElement xElement = XElement.build();
    xElement.setType(FormType.SUBMIT);

    // XmppElement titleElement = XmppElement();
    // titleElement.name = 'title';
    // titleElement.textValue = 'Configuration for "coven" Room';

    // XmppElement instructionElement = XmppElement();
    // instructionElement.name = 'instructions';
    // instructionElement.textValue = 'Your room coven@macbeth has been created!';

    // xElement.addChild(titleElement);
    // xElement.addChild(instructionElement);

    xElement.addField(FieldElement.build(
        varAttr: 'FORM_TYPE',
        value: 'http://jabber.org/protocol/muc#roomconfig'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_roomname', value: config.name));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_roomdesc', value: config.description));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_persistentroom',
        value: config.persistentroom ? '1' : '0'));
    xElement.addField(
        FieldElement.build(varAttr: 'muc#roomconfig_publicroom', value: '1'));
    xElement.addField(FieldElement.build(varAttr: 'public_list', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_passwordprotectedroom', value: '0'));

    xElement.addField(FieldElement.build(varAttr: 'muc#roomconfig_roomsecret'));

    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_getmemberlist', values: config.getmemberlist));

    xElement.addField(
        FieldElement.build(varAttr: 'muc#roomconfig_maxusers', value: '100'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_whois', value: 'moderators'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_membersonly',
        value: config.membersonly ? '1' : '0'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_moderatedroom', value: '1'));
    xElement.addField(
        FieldElement.build(varAttr: 'members_by_default', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_changesubject', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'allow_private_messages', value: config.allowPm ? '1' : '0'));
    xElement
        .addField(FieldElement.build(varAttr: 'allow_query_users', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_allowinvites',
        value: config.allowinvites ? '1' : '0'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_allowmultisessions', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_allowvisitorstatus', value: '1'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_allowvisitornickchange', value: '1'));
    query.addChild(xElement);
    return query;
  }
}

/*

<?xml version="1.0" encoding="UTF-8"?>
<xmpp_stone>
   <iq from="test2b3626e00-7789-11ec-b82f-6dc971962c7e@conference.dev.xmpp.hiapp-chat.com" to="621271021001@dev.xmpp.hiapp-chat.com/iOS-D9BDC54B-0B61-410B-8FBB-633B3196A8C7-cb8cf018-5195-47fd-9785-3ab33511a6ab" id="HJPLWRKPU" type="result">
      <query xmlns="http://jabber.org/protocol/muc#owner">
         <instructions>You need an x:data capable client to configure room</instructions>
         <x xmlns="jabber:x:data" type="form">
            <title>Configuration of room test2b3626e00-7789-11ec-b82f-6dc971962c7e@conference.dev.xmpp.hiapp-chat.com</title>
            <field type="hidden" var="FORM_TYPE">
               <value>http://jabber.org/protocol/muc#roomconfig</value>
            </field>
            <field type="text-single" label="Room title" var="muc#roomconfig_roomname">
               <value />
            </field>
            <field type="text-single" label="Room description" var="muc#roomconfig_roomdesc">
               <value />
            </field>
            <field type="boolean" label="Make room persistent" var="muc#roomconfig_persistentroom">
               <value>0</value>
            </field>
            <field type="boolean" label="Make room public searchable" var="muc#roomconfig_publicroom">
               <value>1</value>
            </field>
            <field type="boolean" label="Make participants list public" var="public_list">
               <value>1</value>
            </field>
            <field type="boolean" label="Make room password protected" var="muc#roomconfig_passwordprotectedroom">
               <value>0</value>
            </field>
            <field type="text-private" label="Password" var="muc#roomconfig_roomsecret">
               <value />
            </field>
            <field type="list-multi" label="Roles and affiliations that may retrieve member list" var="muc#roomconfig_getmemberlist">
               <value>moderator</value>
               <value>participant</value>
               <value>visitor</value>
               <option label="moderator">
                  <value>moderator</value>
               </option>
               <option label="participant">
                  <value>participant</value>
               </option>
               <option label="visitor">
                  <value>visitor</value>
               </option>
            </field>
            <field type="list-single" label="Maximum Number of Occupants" var="muc#roomconfig_maxusers">
               <value>200</value>
               <option label="5">
                  <value>5</value>
               </option>
               <option label="10">
                  <value>10</value>
               </option>
               <option label="20">
                  <value>20</value>
               </option>
               <option label="30">
                  <value>30</value>
               </option>
               <option label="50">
                  <value>50</value>
               </option>
               <option label="100">
                  <value>100</value>
               </option>
               <option label="200">
                  <value>200</value>
               </option>
               <option label="300">
                  <value>300</value>
               </option>
            </field>
            <field type="list-single" label="Present real Jabber IDs to" var="muc#roomconfig_whois">
               <value>moderators</value>
               <option label="moderators only">
                  <value>moderators</value>
               </option>
               <option label="anyone">
                  <value>anyone</value>
               </option>
            </field>
            <field type="boolean" label="Make room members-only" var="muc#roomconfig_membersonly">
               <value>0</value>
            </field>
            <field type="boolean" label="Make room moderated" var="muc#roomconfig_moderatedroom">
               <value>1</value>
            </field>
            <field type="boolean" label="Default users as participants" var="members_by_default">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow users to change the subject" var="muc#roomconfig_changesubject">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow users to send private messages" var="allow_private_messages">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow users to query other users" var="allow_query_users">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow users to send invites" var="muc#roomconfig_allowinvites">
               <value>0</value>
            </field>
            <field type="boolean" label="Allow users to enter room with multiple sessions" var="muc#roomconfig_allowmultisessions">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow visitors to send status text in presence updates" var="muc#roomconfig_allowvisitorstatus">
               <value>1</value>
            </field>
            <field type="boolean" label="Allow visitors to change nickname" var="muc#roomconfig_allowvisitornickchange">
               <value>1</value>
            </field>
         </x>
      </query>
   </iq>
</xmpp_stone>

*/

class JoinGroupChatroomParams {
  final String affiliation;
  final String role;
  final DateTime historySince;
  final bool shouldGetHistory;

  const JoinGroupChatroomParams({
    required this.affiliation,
    required this.role,
    required this.historySince,
    required this.shouldGetHistory,
  });

  static JoinGroupChatroomParams build({
    required DateTime historySince,
    required bool shouldGetHistory,
  }) {
    return JoinGroupChatroomParams(
      affiliation: 'member',
      role: 'participant',
      historySince: historySince,
      shouldGetHistory: shouldGetHistory,
    );
  }

  XmppElement buildJoinRoomXElement() {
    XElement xElement = XElement.build();
    xElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#user'));

    XmppElement itemRole = XmppElement();
    itemRole.name = 'item';
    itemRole.addAttribute(XmppAttribute('affiliation', affiliation));
    itemRole.addAttribute(XmppAttribute('role', role));
    xElement.addChild(itemRole);

    return xElement;
  }

  XmppElement buildAcceptRoomXElement() {
    XElement xElement = XElement.build();
    xElement
        .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));
    return xElement;
  }
}

class AcceptGroupChatroomInvitationParams {
  XmppElement buildAcceptRoomXElement() {
    XElement xElement = XElement.build();
    xElement
        .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));
    return xElement;
  }
}
