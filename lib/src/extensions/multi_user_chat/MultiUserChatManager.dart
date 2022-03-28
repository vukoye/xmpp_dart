import 'dart:async';

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
import 'package:xmpp_stone/src/response/Response.dart';
import 'package:xmpp_stone/src/utils/Random.dart';

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

  final ResponseHandler<IqStanza> responseIqHandler =
      ResponseHandler<IqStanza>();
  final ResponseHandler<PresenceStanza> responsePresenceHandler =
      ResponseHandler<PresenceStanza>();

  MultiUserChatManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    // Listen only having stanza and id existed
    _connection.inStanzasStream
        .where((AbstractStanza? stanza) =>
            stanza != null &&
            (responseIqHandler.keys().contains(stanza.id ?? "") ||
                responsePresenceHandler.keys().contains(stanza.id ?? "")))
        .listen(_processStanza);
  }

  final Map<String, GroupChatroom> _mucList = <String, GroupChatroom>{};

  void _connectionStateProcessor(XmppConnectionState event) {}

  Map<String, GroupChatroom> getAllReceivedVCards() {
    return _mucList;
  }

  bool isReady() {
    return _connection.connectionNegotiationManager
        .isNegotiatorSupport((element) => element is MultiUserChatNegotiator);
  }

  // Try to discover the services
  Future<DiscoverRoomResponse> discoverRoom(Jid roomDotMucDomain) async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET)
      ..fromJid = _connection.fullJid
      ..toJid = roomDotMucDomain
      ..addChild(XmppElement()
        ..name = 'query'
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info')));

    await _connection.writeStanzaWithQueue(iqStanza);

    return responseIqHandler.set<DiscoverRoomResponse>(iqStanza.id!, iqStanza,
        description: 'Discover Multi Chat Room');
  }

  // Get Users by affiliation
  Future<GetUsersResponse> _getUsers(Jid groupJid, String affiliation) async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET)
      ..fromJid = _connection.fullJid
      ..toJid = groupJid
      ..addChild(XmppElement()
        ..name = 'query'
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#admin'))
        ..addChild(XmppElement()
          ..name = 'item'
          ..addAttribute(XmppAttribute('affiliation', affiliation))));

    await _connection.writeStanzaWithQueue(iqStanza);

    return responseIqHandler.set<GetUsersResponse>(iqStanza.id!, iqStanza,
        description: 'Get Multi Chat Room\' users');
  }

  Future<GetUsersResponse> getMembers(Jid groupJid) async {
    return await _getUsers(groupJid, 'member');
  }

  Future<GetUsersResponse> getAdmins(Jid groupJid) async {
    return await _getUsers(groupJid, 'admin');
  }

  Future<GetUsersResponse> getOwners(Jid groupJid) async {
    return await _getUsers(groupJid, 'owner');
  }

  // Add Users by affiliation
  Future<AddUsersResponse> addRemoveMemberInRoom(
      {required Jid groupJid,
      required Iterable<String> memberJids,
      required UserRole userRole,
      required ActionType actionType,
      bool isAsync = false}) async {
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid
      ..toJid = groupJid;

    final queryElement = XmppElement()
      ..name = 'query'
      ..addAttribute(
          XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#admin'));

    // Set Users role value
    var affiliation = '';
    switch (userRole) {
      case UserRole.member:
        affiliation = actionType == ActionType.ADD
            ? UserRole.member.name
            : UserRole.none.name;
        break;
      case UserRole.admin:
        affiliation = actionType == ActionType.ADD
            ? UserRole.admin.name
            : UserRole.member.name;
        break;
      case UserRole.owner:
        affiliation = actionType == ActionType.ADD
            ? UserRole.owner.name
            : UserRole.member.name;
        break;
      default:
      // TODO: throw error
    }

    // Create Users List
    for (final memberJid in memberJids) {
      final item = XmppElement()
        ..name = 'item'
        ..addAttribute(XmppAttribute('affiliation', affiliation))
        ..addAttribute(XmppAttribute('jid', memberJid))
        ..addChild(ReasonElement.build("add user!"));

      queryElement.addChild(item);
    }

    iqStanza.addChild(queryElement);

    await _connection.writeStanzaWithQueue(iqStanza);
    if (!isAsync) {
      await responseIqHandler.setStream<AddUsersResponse>(
          iqStanza.id!, iqStanza,
          description: 'Add User to Multi Chat Room Async');
      return AddUsersResponse();
    } else {
      return responseIqHandler.set<AddUsersResponse>(iqStanza.id!, iqStanza,
          description: 'Add User to Multi Chat Room');
    }
  }

  Future<void> inviteMembers(Jid groupJid, Iterable<String> memberJids) async {
    final stanza =
        MessageStanza(AbstractStanza.getRandomId(), MessageStanzaType.NONE)
          ..toJid = groupJid
          ..fromJid = _connection.fullJid;

    XElement invitationForm = XElement()
      ..addAttribute(
          XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#user'));

    for (final memberJid in memberJids) {
      invitationForm.addChild(InviteElement.build(
          Jid.fromFullJid(memberJid), 'Invitation to groupchat'));
    }

    stanza.addChild(invitationForm);
    await _connection.writeStanzaWithQueue(stanza);
  }

  // Try to request for room configuration
  Future<GetRoomConfigResponse> requestReservedRoomConfig(Jid roomDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) async {
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET)
      ..fromJid = _connection.fullJid
      ..toJid = roomDotMucDomain
      ..addChild(XmppElement()
        ..name = 'query'
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#owner')));

    await _connection.writeStanzaWithQueue(iqStanza);

    return responseIqHandler.set<GetRoomConfigResponse>(iqStanza.id!, iqStanza,
        description: 'Get Multi Chat Room Configuration');
  }

  // Try to request for room configuration
  Future<SetRoomConfigResponse> setRoomConfig(
      Jid roomDotMucDomain, MultiUserChatCreateParams params) async {
    final form = GroupChatroomFormParams(
        config: params.config, roomConfigFields: params.roomConfigFields);
    final queryElement = form.buildForm();

    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid
      ..toJid = roomDotMucDomain
      ..addChild(queryElement);

    await _connection.writeStanzaWithQueue(iqStanza);

    return responseIqHandler.set<SetRoomConfigResponse>(iqStanza.id!, iqStanza,
        description: 'Set Multi Chat Room Configuration');
  }

  Future<CreateRoomResponse> createRoom(Jid _roomDotMucDomain) async {
    final roomDotMucDomain = Jid(_roomDotMucDomain.local,
        _roomDotMucDomain.domain, _connection.fullJid.resource);

    final presenceStanza = PresenceStanza()
      ..id = AbstractStanza.getRandomId()
      ..fromJid = _connection.fullJid
      ..addAttribute(XmppAttribute('to', roomDotMucDomain.fullJid))
      ..addChild(XElement()
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/muc')));

    // XElement xElement = XElement();
    // xElement
    //     .addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/muc'));
    // presenceStanza.addChild(xElement);
    // // print(presenceStanza.buildXmlString());
    // _myUnrespondedPresenceStanzas[presenceStanza.id] =
    //     Tuple2(presenceStanza, completer);
    // _myUnrespondedIqStanzasActions[presenceStanza.id] =
    //     GroupChatroomAction.CREATE_ROOM;
    await _connection.writeStanzaWithQueue(presenceStanza);

    return responsePresenceHandler.set<CreateRoomResponse>(
        presenceStanza.id!, presenceStanza,
        description: 'Create Multi Group Chat Room');
  }

  Future<JoinRoomResponse> joinRoom(
      Jid _roomDotMucDomain, JoinGroupChatroomParams config) async {
    // Change nickname
    final roomDotMucDomain = Jid(_roomDotMucDomain.local,
        _roomDotMucDomain.domain, _connection.fullJid.local);

    final presenceStanza = PresenceStanza()
      ..id = AbstractStanza.getRandomId()
      ..fromJid = _connection.fullJid
      ..addAttribute(XmppAttribute('to', roomDotMucDomain.fullJid))
      ..addChild(config.buildJoinRoomXElement());

    await _connection.writeStanzaWithQueue(presenceStanza);

    return responsePresenceHandler.set<JoinRoomResponse>(
        presenceStanza.id!, presenceStanza,
        description: 'Join Multi User Chat Room');
  }

  Future<AcceptRoomResponse> acceptRoomInvitation(
      Jid _roomDotMucDomain, AcceptGroupChatroomInvitationParams params) async {
    // Change nickname
    final roomDotMucDomain = Jid(_roomDotMucDomain.local,
        _roomDotMucDomain.domain, _connection.fullJid.local);

    final presenceStanza = PresenceStanza()
      ..id = AbstractStanza.getRandomId()
      ..fromJid = _connection.fullJid
      ..addAttribute(XmppAttribute('to', roomDotMucDomain.fullJid))
      ..addChild(params.buildAcceptRoomXElement());

    await _connection.writeStanzaWithQueue(presenceStanza);

    return responsePresenceHandler.set<AcceptRoomResponse>(
        presenceStanza.id!, presenceStanza,
        description: 'Accept Multi User Chat invitation to join the Room');
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

  void _processStanza(AbstractStanza? stanza) {
    responseIqHandler.test(stanza!.id ?? "", (res) {
      late GroupResponse response;
      switch (res.item3) {
        case GetRoomConfigResponse:
          response = GetRoomConfigResponse.parse(stanza);
          break;
        case SetRoomConfigResponse:
          response = SetRoomConfigResponse.parse(stanza);
          break;
        case DiscoverRoomResponse:
          response = DiscoverRoomResponse.parse(stanza);
          break;
        case GetUsersResponse:
          response = GetUsersResponse.parse(stanza);
          break;
        case AddUsersResponse:
          response = AddUsersResponse.parse(stanza);
          break;
      }
      res.item2.complete(response);
    });
    responsePresenceHandler.test(stanza.id ?? "", (res) {
      late GroupResponse response;
      switch (res.item3) {
        case CreateRoomResponse:
          response = CreateRoomResponse.parse(stanza);
          break;
        case JoinRoomResponse:
          response = JoinRoomResponse.parse(stanza);
          break;
        case AcceptRoomResponse:
          response = AcceptRoomResponse.parse(stanza);
          break;
      }
      res.item2.complete(response);
    });
  }
}
