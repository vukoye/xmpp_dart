import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

/// <query xmlns='http://jabber.org/protocol/disco#info'/>
///       <error code='404' type='cancel'>
///         <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
///         <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
///           Conference room does not exist</text>
///       </error>
///
enum GroupChatroomAction {
  NONE,
  FIND_ROOM,
  FIND_RESERVED_CONFIG,
  CREATE_ROOM,
  CREATE_RESERVED_ROOM,
  JOIN_ROOM,
  GET_ROOM_MEMBERS,
  ADD_MEMBERS,
}

class GroupChatroomError {
  final String errorCode;
  final String errorMessage;
  final String errorType;
  final bool hasError;

  const GroupChatroomError(
      {required this.errorCode,
      required this.errorMessage,
      required this.errorType,
      required this.hasError});

  static GroupChatroomError empty() {
    return GroupChatroomError(
        errorCode: '', errorMessage: '', errorType: '', hasError: false);
  }

  static GroupChatroomError parse(AbstractStanza stanza) {
    XmppElement? errorElement = stanza.children.firstWhere(
        (element) => element!.name == 'error',
        orElse: () => XmppElement());
    XmppElement? errorItem = errorElement!.children.firstWhere(
        (element) => element!.name == 'item-not-found',
        orElse: () => XmppElement());
    XmppElement? textItem = errorElement.children.firstWhere(
        (element) => element!.name == 'text',
        orElse: () => XmppElement());

    return GroupChatroomError(
        errorCode: errorElement.getAttribute('code')!.value ?? '',
        errorMessage: textItem!.textValue ?? '',
        errorType: errorItem!.name ?? '',
        hasError: true);
  }
}

class GroupChatroom {
  final GroupChatroomAction action;
  final String roomName;
  final bool isAvailable;
  final XmppElement info;
  final GroupChatroomError error;
  final List<Jid> groupMembers;

  GroupChatroom(
      {required this.action,
      required this.roomName,
      required this.info,
      required this.isAvailable,
      required this.groupMembers,
      required this.error});
}

class InvalidGroupChatroom extends GroupChatroom {
  InvalidGroupChatroom({
    required GroupChatroomAction action,
    required GroupChatroomError error,
    required XmppElement info,
    isAvailable = false,
    roomName = '',
  }) : super(
            action: action,
            roomName: roomName,
            info: info,
            isAvailable: isAvailable,
            groupMembers: [],
            error: error);
}

class GroupChatroomConfig {
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

  const GroupChatroomConfig({
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

  static GroupChatroomConfig build({
    required name,
    required description,
  }) {
    return GroupChatroomConfig(
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

class GroupChatroomConfigForm {
  final GroupChatroomConfig config;
  const GroupChatroomConfigForm({required this.config});

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
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_enablelogging',
    //     value: config.enablelogging ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_changesubject',
    //     value: config.changesubject ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_allowinvites',
    //     value: config.allowinvites ? '1' : '0'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_allowpm', value: config.allowPm ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_maxusers', value: config.maxUser.toString()));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_publicroom',
    //     value: config.publicroom ? '1' : '0'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_persistentroom',
        value: config.persistentroom ? '1' : '0'));
    xElement.addField(FieldElement.build(
        varAttr: 'muc#roomconfig_membersonly',
        value: config.membersonly ? '1' : '0'));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_getmemberlist', values: config.getmemberlist));
    // xElement.addField(FieldElement.build(
    //     varAttr: 'muc#roomconfig_presencebroadcast',
    //     values: config.presencebroadcast));
    query.addChild(xElement);
    return query;
  }
}

class JoinGroupChatroomConfig {
  final String affiliation;
  final String role;
  final DateTime historySince;
  final bool shouldGetHistory;

  const JoinGroupChatroomConfig({
    required this.affiliation,
    required this.role,
    required this.historySince,
    required this.shouldGetHistory,
  });

  static JoinGroupChatroomConfig build({
    required DateTime historySince,
    required bool shouldGetHistory,
  }) {
    return JoinGroupChatroomConfig(
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
}
