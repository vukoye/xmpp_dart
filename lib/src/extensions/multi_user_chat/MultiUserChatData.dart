import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/FieldElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/exception/XmppException.dart';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

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

abstract class GroupResponse extends BaseResponse {
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
    _response.success = false;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      try {
        final xChild = stanza.children.where((element) =>
            element!.name == 'x' &&
            element.getAttribute('xmlns')!.value ==
                'http://jabber.org/protocol/muc#user');
        if (xChild.isNotEmpty) {
          final statusChildren = xChild.first!.children
              .where((element) => element!.name == 'status');
          final statusCodes =
              statusChildren.map((e) => e!.getAttribute('code')!.value!);
          if (statusCodes.contains('110') || statusCodes.contains('100')) {
            _response.success = true;
          }
        }
      } catch (e) {
        Log.e('JoinRoomResponse', 'Error parsing response: $e');
        _response.success = false;
      }
    }

    return _response;
  }
}

class RoomConfigFieldOption {
  final String label;
  final String value;
  const RoomConfigFieldOption({
    required this.label,
    required this.value,
  });
}

class RoomConfigField {
  final String key;
  final String type;
  final String label;
  List<String> values;
  final Iterable<RoomConfigFieldOption> availableValues;

  RoomConfigField({
    required this.key,
    required this.type,
    required this.label,
    required this.values,
    required this.availableValues,
  });

  void setValue(dynamic value) {
    if (['boolean', 'text-private', 'text-single', 'hidden', 'list-single']
        .contains(type)) {
      values = <String>[value as String];
    } else if (type == 'list-multi') {
      values = value as List<String>;
    } else {
      throw SetFormConfigException();
    }
  }

  FieldElement getFieldElement() {
    if (['boolean', 'text-private', 'text-single', 'hidden', 'list-single']
        .contains(type)) {
      return FieldElement.build(
          varAttr: key, value: values.isNotEmpty ? values.first : '');
    } else if (type == 'list-multi') {
      return FieldElement.build(varAttr: key, values: values);
    } else {
      throw SetFormConfigException();
    }
  }

  static RoomConfigField parseFromField(XmppElement xField) {
    final typeAttr = xField.getAttribute('type');

    final type = typeAttr != null ? typeAttr.value ?? "" : "";
    final keyAttr = xField.getAttribute('var');
    final key = keyAttr != null ? keyAttr.value ?? "" : "";
    final labelAttr = xField.getAttribute('label');
    final label = labelAttr != null ? labelAttr.value ?? "" : "";

    final values = xField.children
        .where((element) => element!.name == 'value')
        .map<String>((e) {
      return e!.textValue ?? "";
    });
    final availableValues = xField.children
        .where((element) => element!.name == 'option')
        .map<RoomConfigFieldOption>((e) {
      final label = e!.getAttribute('label')!.value ?? "";
      final value = e.getChild('value')!.textValue ?? "";
      return RoomConfigFieldOption(label: label, value: value);
    });
    return RoomConfigField(
        availableValues: availableValues,
        values: values.toList(),
        type: type,
        label: label,
        key: key);
  }
}

class GetRoomConfigResponse extends GroupResponse {
  late Iterable<RoomConfigField> roomConfigFields;
  late String instructions;
  late String title;

  static GetRoomConfigResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);

    final _response = GetRoomConfigResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      try {
        final queryElement = stanza.getChild('query');
        final instructionsElement = queryElement!.getChild('instructions');
        final xFormElement = queryElement.getChild('x');
        final titleElement = xFormElement!.getChild('title');
        final fieldElements =
            xFormElement.children.where((element) => element!.name == 'field');

        _response.instructions = instructionsElement != null
            ? instructionsElement.textValue ?? ""
            : "";
        _response.title = titleElement!.textValue!;
        _response.roomConfigFields = fieldElements
            .map<RoomConfigField>((e) => RoomConfigField.parseFromField(e!));
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
        _response.users = [];
      }
    } else {
      _response.users = [];
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
