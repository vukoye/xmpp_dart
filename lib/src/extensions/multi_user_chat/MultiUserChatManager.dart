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
import 'package:xmpp_stone/src/response/base_response.dart';
import 'package:xmpp_stone/src/response/response.dart';

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
    return _connection.connectionNegotatiorManager
        .isNegotiateorSupport((element) => element is MultiUserChatNegotiator);
  }

  // Try to discover the services
  Future<DiscoverRoomResponse> discoverRoom(Jid roomtDotMucDomain) {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));

    iqStanza.addChild(queryElement);
    _connection.writeStanza(iqStanza);

    return responseIqHandler.set<DiscoverRoomResponse>(iqStanza.id!, iqStanza);
  }

  // Get Users by affiliation
  Future<GetUsersResponse> _getUsers(Jid groupJid, String affiliation) async {
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

    _connection.writeStanza(iqStanza);

    return responseIqHandler.set<GetUsersResponse>(iqStanza.id!, iqStanza);
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
    final iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = groupJid;
    final queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
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
    if (isAsync) {
      return responseIqHandler.set<AddUsersResponse>(iqStanza.id!, iqStanza);
    } else {
      return AddUsersResponse();
    }
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
  Future<GetRoomConfigResponse> requestReservedRoomConfig(Jid roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/muc#owner'));

    iqStanza.addChild(queryElement);
    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    return responseIqHandler.set<GetRoomConfigResponse>(iqStanza.id!, iqStanza);
  }

  // Try to request for room configuration
  Future<SetRoomConfigResponse> setRoomConfig(
      Jid roomtDotMucDomain, MultiUserChatCreateParams params) {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = roomtDotMucDomain;

    var form = GroupChatroomFormParams(config: params.config);

    var queryElement = form.buildForm();

    iqStanza.addChild(queryElement);
    _connection.writeStanza(iqStanza);
    print(iqStanza.buildXmlString());

    return responseIqHandler.set<SetRoomConfigResponse>(iqStanza.id!, iqStanza);
  }

  Future<CreateRoomResponse> createRoom(Jid _roomtDotMucDomain) {
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

    _connection.writeStanza(presenceStanza);
    print(presenceStanza.buildXmlString());

    return responsePresenceHandler.set<CreateRoomResponse>(
        presenceStanza.id!, presenceStanza);
  }

  Future<JoinRoomResponse> joinRoom(
      Jid _roomtDotMucDomain, JoinGroupChatroomParams config) {
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

    _connection.writeStanza(presenceStanza);

    return responsePresenceHandler.set<JoinRoomResponse>(
        presenceStanza.id!, presenceStanza);
  }

  Future<AcceptRoomResponse> acceptRoomInvitation(Jid _roomtDotMucDomain,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
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
    _connection.writeStanza(presenceStanza);

    return responsePresenceHandler.set<AcceptRoomResponse>(
        presenceStanza.id!, presenceStanza);
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
