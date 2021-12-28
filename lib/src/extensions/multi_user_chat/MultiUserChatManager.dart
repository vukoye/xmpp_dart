import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatParams.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MultiUserChatNegotiator.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

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
        var mucResponse = GroupChatroom(
            action: _myUnrespondedIqStanzasActions[stanzaId]!,
            info: _myUnrespondedIqStanzas[stanzaId]!.item1,
            roomName: '',
            isAvailable: true,
            error: GroupChatroomError.empty());

        _myUnrespondedIqStanzas[stanzaId]!.item2.complete(mucResponse);
        _myUnrespondedIqStanzas
            .remove(_myUnrespondedIqStanzas[stanzaId]!.item1.id);
        _myUnrespondedIqStanzasActions
            .remove(_myUnrespondedIqStanzas[stanzaId]!.item1.id);
      });
    }
  }

  void _shallHandlePresencePrematurely(
      XmppCommunicationConfig communicationConfig, String stanzaId) {
    if (!communicationConfig.shallWaitStanza) {
      Timer(Duration(milliseconds: 200), () {
        var mucResponse = GroupChatroom(
            action: _myUnrespondedIqStanzasActions[stanzaId]!,
            info: _myUnrespondedIqStanzas[stanzaId]!.item1,
            roomName: '',
            isAvailable: true,
            error: GroupChatroomError.empty());
        _myUnrespondedPresenceStanzas[stanzaId]!.item2.complete(mucResponse);
        _myUnrespondedPresenceStanzas
            .remove(_myUnrespondedPresenceStanzas[stanzaId]!.item1.id);
        _myUnrespondedIqStanzasActions
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

    var form = GroupChatroomConfigForm(config: params.config);

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
      Jid _roomtDotMucDomain, JoinGroupChatroomConfig config,
      {XmppCommunicationConfig options =
          const XmppCommunicationConfig(shallWaitStanza: false)}) {
    var completer = Completer<GroupChatroom>();
    var presenceStanza = PresenceStanza();

    Jid roomtDotMucDomain = Jid(_roomtDotMucDomain.local,
        _roomtDotMucDomain.domain, _connection.fullJid.resource);
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
      var muc = GroupChatroom(
          action: action,
          info: stanza,
          roomName: '',
          isAvailable: true,
          error: GroupChatroomError.empty());
      return muc;
    }
    return _handleError(stanza, action);
  }

  GroupChatroom _handleError(
      AbstractStanza stanza, GroupChatroomAction action) {
    return GroupChatroom(
        action: action,
        info: stanza,
        roomName: '',
        isAvailable: false,
        error: GroupChatroomError.parse(stanza));
  }

  void _processStanza(AbstractStanza? stanza) {
    _processIqStanza(stanza);
    _processPresenceStanza(stanza);
  }

  void _processIqStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
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
      }
    }
  }

  void _processPresenceStanza(AbstractStanza? stanza) {
    if (stanza is PresenceStanza) {
      if (_myUnrespondedPresenceStanzas[stanza.id] != null) {
        var unrespondedPresence = _myUnrespondedPresenceStanzas[stanza.id];
        GroupChatroomAction _action =
            _myUnrespondedIqStanzasActions[stanza.id]!;
        print('MUC Stanza type: ' + stanza.type.toString());
        if (stanza.type == IqStanzaType.RESULT) {
          var mucResult = _handleMucResponse(stanza, _action);
          unrespondedPresence!.item2.complete(mucResult);
          // vCardChild is null because of the result response of updating the card
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedPresence!.item2.complete(_handleError(stanza, _action));
        }
      }
    }
  }
}
