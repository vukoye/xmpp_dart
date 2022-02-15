import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/response/base_response.dart';

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

enum UserRole {
  owner,
  admin,
  member,
  none,
}

enum ActionType {
  ADD,
  REMOVE,
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
  final GroupChatroomAction? action;
  final String roomName;
  final bool? isAvailable;
  final XmppElement? info;
  final GroupChatroomError? error;
  final List<Jid> groupMembers;

  GroupChatroom(
      {this.action,
      required this.roomName,
      this.info,
      this.isAvailable,
      required this.groupMembers,
      this.error});
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

abstract class GroupResponse {
  late bool success;
  late BaseResponse response;
}

class CreateRoomResponse extends GroupResponse {
  static CreateRoomResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = CreateRoomResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class JoinRoomResponse extends GroupResponse {
  static JoinRoomResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = JoinRoomResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      try {
        final xChild = stanza.getChild('x')!;
        final status = xChild.getChild('status')!;
        final statusCode = status.getAttribute('code')!.value!; //  == '110
        if (statusCode == '110') {
          _response.success = true;
        }
      } catch (e) {
        _response.success = false;
      }
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class GetRoomConfigResponse extends GroupResponse {
  static GetRoomConfigResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = GetRoomConfigResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class SetRoomConfigResponse extends GroupResponse {
  static SetRoomConfigResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = SetRoomConfigResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class AcceptRoomResponse extends GroupResponse {
  static AcceptRoomResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = AcceptRoomResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class DiscoverRoomResponse extends GroupResponse {
  static DiscoverRoomResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = DiscoverRoomResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class GetUsersResponse extends GroupResponse {
  late Iterable<Jid> users;
  static GetUsersResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = GetUsersResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      try {
        var queryChild = stanza.getChild('query')!;
        final items =
            queryChild.children.where((child) => child!.name == 'item');
        final groupMembers = items.map((item) {
          return Jid.fromFullJid(item!.getAttribute('jid')!.value!);
        });
        _response.users = groupMembers;
        _response.success = true;
      } catch (e) {
        _response.success = false;
      }
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class AddUsersResponse extends GroupResponse {
  static AddUsersResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = AddUsersResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}
