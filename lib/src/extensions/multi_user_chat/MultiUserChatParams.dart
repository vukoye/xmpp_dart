import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';

class MultiUserChatCreateParams {
  final GroupChatroomParams config;
  final XmppCommunicationConfig options;
  final List<RoomConfigField> roomConfigFields;
  const MultiUserChatCreateParams({
    required this.config,
    required this.options,
    required this.roomConfigFields,
  });

  static MultiUserChatCreateParams build(
      {GroupChatroomParams config = const GroupChatroomParams(
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
      List<RoomConfigField> roomConfigFields = const []}) {
    return MultiUserChatCreateParams(
        config: config, options: options, roomConfigFields: roomConfigFields);
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
  final List<RoomConfigField> roomConfigFields;
  const GroupChatroomFormParams(
      {required this.config, required this.roomConfigFields});

  XmppElement buildInstantRoom() {
    QueryElement query = QueryElement();
    query.setXmlns('http://jabber.org/protocol/muc#owner');
    XElement xElement = XElement.build();
    xElement.setType(FormType.SUBMIT);
    query.addChild(xElement);
    return query;
  }

  // Mongooseim

  // XmppElement buildForm() {
  //   QueryElement query = QueryElement();
  //   query.setXmlns('http://jabber.org/protocol/muc#owner');
  //   XElement xElement = XElement.build();
  //   xElement.setType(FormType.SUBMIT);
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'FORM_TYPE',
  //       value: 'http://jabber.org/protocol/muc#roomconfig'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_roomname', value: config.name));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_roomdesc', value: config.description));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_persistentroom',
  //       value: config.persistentroom ? '1' : '0'));
  //   xElement.addField(
  //       FieldElement.build(varAttr: 'muc#roomconfig_publicroom', value: '1'));
  //   xElement.addField(FieldElement.build(varAttr: 'public_list', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_passwordprotectedroom', value: '0'));

  //   xElement.addField(FieldElement.build(varAttr: 'muc#roomconfig_roomsecret'));

  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_getmemberlist', values: config.getmemberlist));

  //   xElement.addField(
  //       FieldElement.build(varAttr: 'muc#roomconfig_maxusers', value: '100'));
  //   xElement.addField(
  //       FieldElement.build(varAttr: 'muc#roomconfig_whois', value: 'anyone'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_membersonly',
  //       value: config.membersonly ? '1' : '0'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_moderatedroom', value: '1'));
  //   xElement.addField(
  //       FieldElement.build(varAttr: 'members_by_default', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_changesubject', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'allow_private_messages', value: config.allowPm ? '1' : '0'));
  //   xElement
  //       .addField(FieldElement.build(varAttr: 'allow_query_users', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_allowinvites',
  //       value: config.allowinvites ? '1' : '0'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_allowmultisessions', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_allowvisitorstatus', value: '1'));
  //   xElement.addField(FieldElement.build(
  //       varAttr: 'muc#roomconfig_allowvisitornickchange', value: '1'));
  //   query.addChild(xElement);
  //   return query;
  // }
  // Ejabbered
  XmppElement buildForm() {
    QueryElement query = QueryElement();
    query.setXmlns('http://jabber.org/protocol/muc#owner');
    XElement xElement = XElement.build();
    xElement.setType(FormType.SUBMIT);

    roomConfigFields.forEach((element) {
      xElement.addChild(element.getFieldElement());
    });
    // xElement.addField(FieldElement.build(
    //     varAttr: 'FORM_TYPE',
    //     value: 'http://jabber.org/protocol/muc#roomconfig'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_roomname', value: config.name));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_roomdesc', value: config.description));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'muc#roomconfig_lang', value: 'en'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_persistentroom',
    //     value: config.persistentroom ? '1' : '0'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'muc#roomconfig_publicroom', value: '1'));
    // xElement.addField(FieldElement.build(varAttr: 'public_list', value: '1'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_passwordprotectedroom', value: '0'));

    // xElement.addField(FieldElement.build(varAttr: 'muc#roomconfig_roomsecret'));

    // xElement.addField(
    //     FieldElement.build(varAttr: 'muc#roomconfig_maxusers', value: '100'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'muc#roomconfig_whois', value: 'anyone'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_presencebroadcast',
    //     values: config.presencebroadcast));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_membersonly',
    //     value: config.membersonly ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_moderatedroom', value: '1'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'members_by_default', value: '1'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_changesubject', value: '1'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'allow_private_messages', value: config.allowPm ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'allow_private_messages_from_visitors', value: 'anyone'));
    // xElement
    //     .addField(FieldElement.build(varAttr: 'allow_query_users', value: '1'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_allowinvites',
    //     value: config.allowinvites ? '1' : '0'));
    // // xElement.addField(FieldElement.build(
    // //     varAttr: 'muc#roomconfig_allowmultisessions', value: '1'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'allow_visitor_status', value: '1'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'allow_visitor_nickchange', value: '1'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'allow_voice_requests', value: '1'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'allow_subscription', value: '1'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'voice_request_min_interval', value: '1800'));
    // xElement.addField(
    //     FieldElement.build(varAttr: 'muc#roomconfig_pubsub', value: ''));
    // xElement.addField(FieldElement.build(varAttr: 'mam', value: '1'));
    query.addChild(xElement);
    return query;
  }
}

/*

MONGOOSEIM
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

-------------

## EJABBERED
<?xml version="1.0" encoding="UTF-8"?>
<xmpp_stone>
   <iq xml:lang="en" to="627075027401@dev.ejabberd.xmpp.hiapp-chat.com/cd539502dde769f7f3bc45cdc93a1e6a3786f614fef516032578263231115ee9" from="gg4063dc530-ab69-11ec-858f-09cddfaf8df1@conference.dev.ejabberd.xmpp.hiapp-chat.com" type="result" id="ATIDCRCDD">
      <query xmlns="http://jabber.org/protocol/muc#owner">
         <x xmlns="jabber:x:data" type="form">
            <title>Configuration of room gg4063dc530-ab69-11ec-858f-09cddfaf8df1@conference.dev.ejabberd.xmpp.hiapp-chat.com</title>
            <field var="FORM_TYPE" type="hidden">
               <value>http://jabber.org/protocol/muc#roomconfig</value>
            </field>
            <field var="muc#roomconfig_roomname" type="text-single" label="Room title" />
            <field var="muc#roomconfig_roomdesc" type="text-single" label="Room description" />
            <field var="muc#roomconfig_lang" type="text-single" label="Natural Language for Room Discussions">
               <value>en</value>
            </field>
            <field var="muc#roomconfig_persistentroom" type="boolean" label="Make room persistent">
               <value>0</value>
            </field>
            <field var="muc#roomconfig_publicroom" type="boolean" label="Make room public searchable">
               <value>1</value>
            </field>
            <field var="public_list" type="boolean" label="Make participants list public">
               <value>1</value>
            </field>
            <field var="muc#roomconfig_passwordprotectedroom" type="boolean" label="Make room password protected">
               <value>0</value>
            </field>
            <field var="muc#roomconfig_roomsecret" type="text-private" label="Password" />
            <field var="muc#roomconfig_maxusers" type="list-single" label="Maximum Number of Occupants">
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
            </field>
            <field var="muc#roomconfig_whois" type="list-single" label="Present real Jabber IDs to">
               <value>moderators</value>
               <option label="Moderators Only">
                  <value>moderators</value>
               </option>
               <option label="Anyone">
                  <value>anyone</value>
               </option>
            </field>
            <field var="muc#roomconfig_presencebroadcast" type="list-multi" label="Roles for which Presence is Broadcasted">
               <value>moderator</value>
               <value>participant</value>
               <value>visitor</value>
               <option label="Moderator">
                  <value>moderator</value>
               </option>
               <option label="Participant">
                  <value>participant</value>
               </option>
               <option label="Visitor">
                  <value>visitor</value>
               </option>
            </field>
            <field var="muc#roomconfig_membersonly" type="boolean" label="Make room members-only">
               <value>0</value>
            </field>
            <field var="muc#roomconfig_moderatedroom" type="boolean" label="Make room moderated">
               <value>1</value>
            </field>
            <field var="members_by_default" type="boolean" label="Default users as participants">
               <value>1</value>
            </field>
            <field var="muc#roomconfig_changesubject" type="boolean" label="Allow users to change the subject">
               <value>1</value>
            </field>
            <field var="allow_private_messages" type="boolean" label="Allow users to send private messages">
               <value>1</value>
            </field>
            <field var="allow_private_messages_from_visitors" type="list-single" label="Allow visitors to send private messages to">
               <value>anyone</value>
               <option label="Nobody">
                  <value>nobody</value>
               </option>
               <option label="Moderators Only">
                  <value>moderators</value>
               </option>
               <option label="Anyone">
                  <value>anyone</value>
               </option>
            </field>
            <field var="allow_query_users" type="boolean" label="Allow users to query other users">
               <value>1</value>
            </field>
            <field var="muc#roomconfig_allowinvites" type="boolean" label="Allow users to send invites">
               <value>0</value>
            </field>
            <field var="allow_visitor_status" type="boolean" label="Allow visitors to send status text in presence updates">
               <value>1</value>
            </field>
            <field var="allow_visitor_nickchange" type="boolean" label="Allow visitors to change nickname">
               <value>1</value>
            </field>
            <field var="allow_voice_requests" type="boolean" label="Allow visitors to send voice requests">
               <value>1</value>
            </field>
            <field var="allow_subscription" type="boolean" label="Allow subscription">
               <value>0</value>
            </field>
            <field var="voice_request_min_interval" type="text-single" label="Minimum interval between voice requests (in seconds)">
               <value>1800</value>
            </field>
            <field var="muc#roomconfig_pubsub" type="text-single" label="XMPP URI of Associated Publish-Subscribe Node">
               <value />
            </field>
            <field var="enable_hats" type="boolean" label="Enable hats">
               <value>0</value>
            </field>
            <field var="mam" type="boolean" label="Enable message archiving">
               <value>1</value>
            </field>
         </x>
      </query>
   </iq>
   <r xmlns="urn:xmpp:sm:3" />
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
    xElement
        .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));

    XmppElement itemHistory = XmppElement();
    itemHistory.name = 'history';
    itemHistory.addAttribute(XmppAttribute('since', historySince.toString()));
    xElement.addChild(itemHistory);

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
  final DateTime historySince;
  final bool shouldGetHistory;

  const AcceptGroupChatroomInvitationParams({
    required this.historySince,
    required this.shouldGetHistory,
  });
  XmppElement buildAcceptRoomXElement() {
    XElement xElement = XElement.build();
    xElement
        .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));
    if (shouldGetHistory) {
      XmppElement itemHistory = XmppElement();
      itemHistory.name = 'history';
      itemHistory.addAttribute(XmppAttribute('since', historySince.toString()));
    }
    return xElement;
  }
}
