import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

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
  ACCEPT_ROOM,
  GET_ROOM_MEMBERS,
  ADD_USERS,
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
    // TODO: handle forbiden error
    return GroupChatroomError(
        errorCode: errorElement.getAttribute('code') != null
            ? errorElement.getAttribute('code')!.value ?? ''
            : '',
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

