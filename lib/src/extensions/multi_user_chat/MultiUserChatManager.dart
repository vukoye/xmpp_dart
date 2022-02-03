import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/elements/messages/invitation/InviteElement.dart';
import 'package:xmpp_stone/src/elements/messages/invitation/ReasonElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/MessageStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatParams.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MultiUserChatNegotiator.dart';

class MultiUserChatManager {
  static Map<Connection, MultiUserChatManager> instances =
      <Connection, MultiUserChatManager>{};

  static MultiUserChatManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = MultiUserChatManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  final Connection _connection;

  MultiUserChatManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  final Map<String?, GroupChatroomAction> _myUnrespondedIqStanzasActions =
      <String?, GroupChatroomAction>{};

  final Map<String?, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String?, Tuple2<IqStanza, Completer>>{};

  final Map<String?, Tuple2<PresenceStanza, Completer>>
      _myUnrespondedPresenceStanzas =
      <String?, Tuple2<PresenceStanza, Completer>>{};

  final Map<String, GroupChatroom> _mucList = <String, GroupChatroom>{};

  void _connectionStateProcessor(XmppConnectionState event) {}

  Map<String, GroupChatroom> getAllReceivedVCards() {
    return _mucList;
  }

  bool isReady() {
    return _connection.connectionNegotatiorManager
        .isNegotiateorSupport((element) => element is MultiUserChatNegotiator);
  }

  void _shallHandleStanzaPrematurely(
      XmppCommunicationConfig communicationConfig, String stanzaId) {
    if (!communicationConfig.shallWaitStanza) {
      Timer(Duration(milliseconds: 200), () {
        var action = GroupChatroomAction.NONE;
        if (_myUnrespondedIqStanzasActions.containsKey(stanzaId)) {
          action = _myUnrespondedIqStanzasActions[stanzaId]!;
          _myUnrespondedIqStanzasActions
              .remove(_myUnrespondedIqStanzas[stanzaId]!.item1.id);
        }
        var mucResponse = GroupChatroom(
            action: action,
            info: _myUnrespondedIqStanzas[stanzaId]!.item1,
            roomName: '',
            isAvailable: true,
            groupMembers: [],
            error: GroupChatroomError.empty());

        if (!_myUnrespondedIqStanzas[stanzaId]!.item2.isCompleted) {
          _myUnrespondedIqStanzas[stanzaId]!.item2.complete(mucResponse);
        }
        _myUnrespondedIqStanzas
            .remove(_myUnrespondedIqStanzas[stanzaId]!.item1.id);
      });
    }
  }

  void _shallHandlePresencePrematurely(
      XmppCommunicationConfig communicationConfig, String stanzaId) {
    if (!communicationConfig.shallWaitStanza) {
      Timer(Duration(milliseconds: 200), () {
        var action = GroupChatroomAction.NONE;
        if (_myUnrespondedIqStanzasActions.containsKey(stanzaId)) {
          action = _myUnrespondedIqStanzasActions[stanzaId]!;
          _myUnrespondedIqStanzasActions
              .remove(_myUnrespondedPresenceStanzas[stanzaId]!.item1.id);
        }
        var mucResponse = GroupChatroom(
            action: action,
            info: _myUnrespondedPresenceStanzas[stanzaId]!.item1,
            roomName: '',
            isAvailable: true,
            groupMembers: [],
            error: GroupChatroomError.empty());
        if (!_myUnrespondedPresenceStanzas[stanzaId]!.item2.isCompleted) {
          _myUnrespondedPresenceStanzas[stanzaId]!.item2.complete(mucResponse);
        }
        _myUnrespondedPresenceStanzas
            .remove(_myUnrespondedPresenceStanzas[stanzaId]!.item1.id);
      });
    }
  }

  // Try to discover the services
  Future<GroupChatroom> discoverRoom(Jid roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));

    iqStanza.addChild(queryElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _myUnrespondedIqStanzasActions[iqStanza.id] = GroupChatroomAction.FIND_ROOM;
    _connection.writeStanza(iqStanza);

    _shallHandleStanzaPrematurely(options, iqStanza.id ?? "");
    return completer.future;
  }

  Future<GroupChatroom> _getUsers(Jid groupJid, String affiliation) async {
    var completer = Completer<GroupChatroom>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = groupJid;

    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#admin'));
    var child = XmppElement();
    child.name = 'item';
    child.addAttribute(XmppAttribute('affiliation', affiliation));
    queryElement.addChild(child);
    iqStanza.addChild(queryElement);

    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _myUnrespondedIqStanzasActions[iqStanza.id] =
        GroupChatroomAction.GET_ROOM_MEMBERS;

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<GroupChatroom> getMembers(Jid groupJid) async {
    return await _getUsers(groupJid, 'member');
  }

  Future<GroupChatroom> getAdmins(Jid groupJid) async {
    return await _getUsers(groupJid, 'admin');
  }

  Future<GroupChatroom> getOwners(Jid groupJid) async {
    return await _getUsers(groupJid, 'owner');
  }

  Future<void> _addUsers(Jid groupJid, Iterable<String> memberJids, String affiliation) async {
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = groupJid;

    final queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#admin'));

    for (final memberJid in memberJids) {
      final item = XmppElement();
      item.name = 'item';
      item.addAttribute(XmppAttribute('affiliation', affiliation));
      item.addAttribute(XmppAttribute('jid', memberJid));
      // add reason
      final reason = ReasonElement.build("add user!");
      item.addChild(reason);

      queryElement.addChild(item);
    }

    iqStanza.addChild(queryElement);

    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    return Future.value();
  }

  Future<GroupChatroom> _addUsersAsync(Jid groupJid, Iterable<String> memberJids, String affiliation) async {
    var completer = Completer<GroupChatroom>();

    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = groupJid;

    final queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#admin'));

    for (final memberJid in memberJids) {
      final item = XmppElement();
      item.name = 'item';
      item.addAttribute(XmppAttribute('affiliation', affiliation));
      item.addAttribute(XmppAttribute('jid', memberJid));
      // add reason
      final reason = ReasonElement.build("add member!");
      item.addChild(reason);

      queryElement.addChild(item);
    }

    iqStanza.addChild(queryElement);

    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _myUnrespondedIqStanzasActions[iqStanza.id] =
        GroupChatroomAction.ADD_USERS;

    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    return completer.future;
  }

  Future<void> addMembers(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsers(groupJid, memberJids, 'member');
  }

  Future<void> addAdmins(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsers(groupJid, memberJids, 'admin');
  }

  Future<void> addOwners(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsers(groupJid, memberJids, 'owner');
  }

  Future<GroupChatroom> addMembersAsync(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsersAsync(groupJid, memberJids, 'member');
  }

  Future<GroupChatroom> addAdminsAsync(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsersAsync(groupJid, memberJids, 'admin');
  }

  Future<GroupChatroom> addOwnersAsync(Jid groupJid, Iterable<String> memberJids) async {
    return await _addUsersAsync(groupJid, memberJids, 'owner');
  }

  Future<void> inviteMembers(Jid groupJid, Iterable<String> memberJids) async {
    final stanza =
        MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.NONE);
    stanza.toJid = groupJid;
    stanza.fromJid = _connection.fullJid;

    XElement invitationForm = XElement();
    invitationForm.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#user'));
    for (final memberJid in memberJids) {
      invitationForm.addChild(InviteElement.build(
          Jid.fromFullJid(memberJid), 'Invitation to groupchat'));
    }

    stanza.addChild(invitationForm);
    print(stanza.buildXmlString());
    _connection.writeStanza(stanza);
  }

  // Try to request for room configuration
  Future<GroupChatroom> requestReservedRoomConfig(Jid roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#owner'));

    iqStanza.addChild(queryElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _myUnrespondedIqStanzasActions[iqStanza.id] =
        GroupChatroomAction.FIND_RESERVED_CONFIG;
    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    _shallHandleStanzaPrematurely(options, iqStanza.id ?? "");

    return completer.future;
  }

  // Try to request for room configuration
  Future<GroupChatroom> setRoomConfig(
      Jid roomtDotMucDomain, MultiUserChatCreateParams params) {
    var completer = Completer<GroupChatroom>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var form = GroupChatroomFormParams(config: params.config);

    var queryElement = form.buildForm();

    iqStanza.addChild(queryElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _myUnrespondedIqStanzasActions[iqStanza.id] =
        GroupChatroomAction.CREATE_RESERVED_ROOM;
    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    _shallHandleStanzaPrematurely(params.options, iqStanza.id ?? "");

    return completer.future;
  }

  Future<GroupChatroom> createRoom(Jid _roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var presenceStanza = PresenceStanza();
    presenceStanza.id = AbstractStanza.getRandomId();

    Jid roomtDotMucDomain = Jid(_roomtDotMucDomain.local,
        _roomtDotMucDomain.domain, _connection.fullJid.resource);
    presenceStanza.fromJid = _connection.fullJid;
    presenceStanza.addAttribute(XmppAttribute('to', roomtDotMucDomain.fullJid));

    XElement xElement = XElement();
    xElement
        .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));
    presenceStanza.addChild(xElement);
    print(presenceStanza.buildXmlString());
    _myUnrespondedPresenceStanzas[presenceStanza.id] =
        Tuple2(presenceStanza, completer);
    _myUnrespondedIqStanzasActions[presenceStanza.id] =
        GroupChatroomAction.CREATE_ROOM;
    _connection.writeStanza(presenceStanza);

    _shallHandlePresencePrematurely(options, presenceStanza.id ?? "");
    return completer.future;
  }

  Future<GroupChatroom> joinRoom(
      Jid _roomtDotMucDomain, JoinGroupChatroomParams config,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var presenceStanza = PresenceStanza();
    presenceStanza.id = AbstractStanza.getRandomId();

    // Change nickname
    Jid roomtDotMucDomain = Jid(
        _roomtDotMucDomain.local,
        _roomtDotMucDomain.domain,
        '${_connection.fullJid.userAtDomain}#${_connection.fullJid.resource}');
    presenceStanza.fromJid = _connection.fullJid;
    presenceStanza.addAttribute(XmppAttribute('to', roomtDotMucDomain.fullJid));

    presenceStanza.addChild(config.buildJoinRoomXElement());
    print(presenceStanza.buildXmlString());

    _myUnrespondedPresenceStanzas[presenceStanza.id] =
        Tuple2(presenceStanza, completer);
    _myUnrespondedIqStanzasActions[presenceStanza.id] =
        GroupChatroomAction.JOIN_ROOM;
    _connection.writeStanza(presenceStanza);

    _shallHandlePresencePrematurely(options, presenceStanza.id ?? "");
    return completer.future;
  }

  Future<GroupChatroom> acceptRoomInvitation(Jid _roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var presenceStanza = PresenceStanza();
    presenceStanza.id = AbstractStanza.getRandomId();

    // Change nickname
    Jid roomtDotMucDomain = Jid(
        _roomtDotMucDomain.local,
        _roomtDotMucDomain.domain,
        '${_connection.fullJid.userAtDomain}#${_connection.fullJid.resource}');
    presenceStanza.fromJid = _connection.fullJid;
    presenceStanza.addAttribute(XmppAttribute('to', roomtDotMucDomain.fullJid));

    presenceStanza.addChild(
        AcceptGroupChatroomInvitationParams().buildAcceptRoomXElement());
    print(presenceStanza.buildXmlString());

    _myUnrespondedPresenceStanzas[presenceStanza.id] =
        Tuple2(presenceStanza, completer);
    _myUnrespondedIqStanzasActions[presenceStanza.id] =
        GroupChatroomAction.ACCEPT_ROOM;
    _connection.writeStanza(presenceStanza);

    _shallHandlePresencePrematurely(options, presenceStanza.id ?? "");
    return completer.future;
  }

  ///
  /// <xmpp_stone>
  ///   <iq from='tseting@conference.dev.xmpp.hiapp-chat.com' to='627775027401@dev.xmpp.hiapp-chat.com/c714d7b25ea373e31640-246580-77685' type='error' xml:lang='en' id='MVEPQWBJA'>
  ///     <query xmlns='http://jabber.org/protocol/disco#info'/>
  ///       <error code='404' type='cancel'>
  ///         <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
  ///         <text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
  ///           Conference room does not exist</text>
  ///       </error>
  ///   </iq>
  /// </xmpp_stone>
  ///
  GroupChatroom _handleMucResponse(
      AbstractStanza stanza, GroupChatroomAction action) {
    var queryChild = stanza.getChild('query');
    if (queryChild != null) {
      // TODO: refactor to use only one return
      if (action == GroupChatroomAction.GET_ROOM_MEMBERS) {
        final items =
            queryChild.children.where((child) => child!.name == 'item');
        final groupMembers = items.map((item) {
          return Jid.fromFullJid(item!.getAttribute('jid')!.value!);
        }).toList();

        return GroupChatroom(
            action: action,
            info: stanza,
            roomName: '',
            isAvailable: true,
            groupMembers: groupMembers,
            error: GroupChatroomError.empty());
      } else {
        var muc = GroupChatroom(
            action: action,
            info: stanza,
            roomName: '',
            isAvailable: true,
            groupMembers: [],
            error: GroupChatroomError.empty());
        return muc;
      }
    }
    return _handleError(stanza, action);
  }

  GroupChatroom _handleMucPresenceResponse(
      AbstractStanza stanza, GroupChatroomAction action) {
    var xChild = stanza.getChild('x');
    if (xChild != null) {
      final status = xChild.getChild('status');
      if (status != null && status.getAttribute('code')!.value == '110') {
        var muc = GroupChatroom(
            action: action,
            info: stanza,
            roomName: '',
            isAvailable: true,
            groupMembers: [],
            error: GroupChatroomError.empty());
        return muc;
      }
    }
    return _handlePresenceError(stanza, action);
  }

  GroupChatroom _handleError(
      AbstractStanza stanza, GroupChatroomAction action) {
    return GroupChatroom(
        action: action,
        info: stanza,
        roomName: '',
        isAvailable: false,
        groupMembers: [],
        error: GroupChatroomError.parse(stanza));
  }

  GroupChatroom _handlePresenceError(
      AbstractStanza stanza, GroupChatroomAction action) {
    return GroupChatroom(
      action: action,
      info: stanza,
      roomName: '',
      isAvailable: false,
      groupMembers: [],
      error: GroupChatroomError.empty(),
    );
    // error: GroupChatroomError.parse(stanza));
  }

  void _processStanza(AbstractStanza? stanza) {
    _processIqStanza(stanza);
    _processPresenceStanza(stanza);
  }

  void _processIqStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza && _myUnrespondedIqStanzas.containsKey(stanza.id)) {
      if (_myUnrespondedIqStanzas[stanza.id] != null) {
        var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
        GroupChatroomAction _action =
            _myUnrespondedIqStanzasActions[stanza.id]!;
        print('MUC Stanza type: ' + stanza.type.toString());
        if (stanza.type == IqStanzaType.RESULT) {
          var mucResult = _handleMucResponse(stanza, _action);
          unrespondedStanza!.item2.complete(mucResult);
          // vCardChild is null because of the result response of updating the card
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedStanza!.item2.complete(_handleError(stanza, _action));
        }
        // TODO: to double check
        _myUnrespondedIqStanzas.remove(stanza.id);
        
      }
    }
  }

  void _processPresenceStanza(AbstractStanza? stanza) {
    if (stanza is PresenceStanza &&
        _myUnrespondedPresenceStanzas.containsKey(stanza.id)) {
      if (_myUnrespondedPresenceStanzas[stanza.id] != null) {
        var unrespondedPresence = _myUnrespondedPresenceStanzas[stanza.id];
        GroupChatroomAction _action =
            _myUnrespondedIqStanzasActions[stanza.id]!;
        print('MUC Stanza type: ' + stanza.type.toString());
        final xElement = stanza.getChild('x');
        if (xElement != null) {
          final status = xElement.getChild('status');
          if (status != null && status.getAttribute('code')!.value == '110') {
            var mucResult = _handleMucPresenceResponse(stanza, _action);
            unrespondedPresence!.item2.complete(mucResult);
          } else {
            unrespondedPresence!.item2
                .complete(_handlePresenceError(stanza, _action));
          }
        }
      }
    }
  }
}
