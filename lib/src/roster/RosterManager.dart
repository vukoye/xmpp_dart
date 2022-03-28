import 'dart:async';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';
import 'package:xmpp_stone/src/response/Response.dart';
import 'package:xmpp_stone/src/roster/Buddy.dart';
import 'package:xmpp_stone/src/roster/RosterResponse.dart';

//todo check for rfc6121 2.6.2
//todo add support for jid groups
class RosterManager {
  static Map<Connection?, RosterManager> instances =
      <Connection?, RosterManager>{};

  static RosterManager getInstance(Connection? connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = RosterManager(connection!);
      instances[connection] = manager;
    }
    return manager;
  }

  static final ResponseHandler<IqStanza> responseHandler =
      ResponseHandler<IqStanza>();

  final StreamController<List<Buddy>> _rosterController =
      StreamController<List<Buddy>>.broadcast();

  Stream<List<Buddy>> get rosterStream {
    return _rosterController.stream;
  }

  final Map<Jid, Buddy> _rosterMap = <Jid, Buddy>{};

  late Connection _connection;

  Future<QueryRosterResponse> queryForRoster() async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    var element = XmppElement();
    element.name = 'query';
    element.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(element);

    await _connection.writeStanzaWithQueue(iqStanza);

    return responseHandler.set<QueryRosterResponse>(iqStanza.id!, iqStanza,
        description: 'Query user roster');
  }

  List<Buddy> getRoster() {
    return _rosterMap.values.toList();
  }

  Future<SetRosterResponse> updateRosterItem(Buddy rosterItem) {
    return addRosterItem(rosterItem);
  }

  Future<SetRosterResponse> addRosterItem(Buddy rosterItem) async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(queryElement);
    var itemElement = XmppElement();
    itemElement.name = 'item';
    queryElement.addChild(itemElement);
    itemElement
        .addAttribute(XmppAttribute('jid', rosterItem.jid!.userAtDomain));
    if (rosterItem.name != null) {
      itemElement.addAttribute(XmppAttribute('name', rosterItem.name));
    }
    await _connection.writeStanzaWithQueue(iqStanza);
    return responseHandler.set<SetRosterResponse>(iqStanza.id!, iqStanza,
        description: 'Set/Update/Add Roster');
  }

  Future<RemoveRosterResponse> removeRosterItem(Buddy rosterItem) async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(queryElement);
    var itemElement = XmppElement();
    itemElement.name = 'item';
    queryElement.addChild(itemElement);
    itemElement
        .addAttribute(XmppAttribute('jid', rosterItem.jid!.userAtDomain));
    itemElement.addAttribute(XmppAttribute('subscription', 'remove'));
    await _connection.writeStanzaWithQueue(iqStanza);
    return responseHandler.set<RemoveRosterResponse>(iqStanza.id!, iqStanza,
        description: 'Remove roster');
  }

  RosterManager(Connection connection) {
    _connection = connection;
    connection.connectionStateStream.listen(_connectionStateProcessor);
    connection.inStanzasStream.listen(_processStanza);
  }

  void _connectionStateProcessor(XmppConnectionState state) {
    if (state == XmppConnectionState.Closed) {
      _rosterMap.clear();
      _rosterController.add([]);
    }
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      responseHandler.test(stanza.id!, (res) {
        late BaseResponse response;
        switch (res.item3) {
          case QueryRosterResponse:
            response = QueryRosterResponse.parse(stanza, _connection);

            _rosterMap.clear();
            _rosterMap.addAll((response as QueryRosterResponse).rosterMap);
            _fireOnRosterListChanged();
            break;
          case SetRosterResponse:
            response = SetRosterResponse.parse(stanza, _connection);
            break;
          case RemoveRosterResponse:
            response = RemoveRosterResponse.parse(stanza, _connection);
            break;
        }
        res.item2.complete(response);
      });
    }
  }

  void _fireOnRosterListChanged() {
    var rosterList = _rosterMap.values.toList();
    _rosterController.add(rosterList);
  }
}
