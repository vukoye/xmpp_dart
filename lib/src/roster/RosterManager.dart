import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/roster/Buddy.dart';

//todo check for rfc6121 2.6.2
//todo add support for jid groups
class RosterManager {
  static Map<Connection, RosterManager> instances = {};

  static RosterManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = RosterManager(connection);
      instances[connection] = manager;
    }
    return manager;
  }

  static void removeInstance(Connection connection) {
    instances[connection]?._abstractStanzaSubscription.cancel();
    instances[connection]?._xmppConnectionStateSubscription.cancel();
    instances.remove(connection);
  }

  final Map<String, Tuple2<IqStanza, Completer?>> _myUnrespondedIqStanzas = {};

  final StreamController<List<Buddy>> _rosterController =
      StreamController<List<Buddy>>.broadcast();

  late StreamSubscription<XmppConnectionState> _xmppConnectionStateSubscription;
  late StreamSubscription<AbstractStanza?> _abstractStanzaSubscription;

  Stream<List<Buddy>> get rosterStream {
    return _rosterController.stream;
  }

  final Map<Jid, Buddy> _rosterMap = {};

  late Connection _connection;

  void queryForRoster() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    var element = XmppElement('query');
    element.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(element);
    _myUnrespondedIqStanzas[iqStanza.id!] = Tuple2(iqStanza, null);
    _connection.writeStanza(iqStanza);
  }

  List<Buddy> getRoster() {
    return _rosterMap.values.toList();
  }

  Future<IqStanzaResult> updateRosterItem(Buddy rosterItem) {
    return addRosterItem(rosterItem);
  }

  Future<IqStanzaResult> addRosterItem(Buddy rosterItem) {
    var completer = Completer<IqStanzaResult>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var queryElement = XmppElement('query');
    queryElement.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(queryElement);
    var itemElement = XmppElement('item');
    queryElement.addChild(itemElement);
    itemElement
        .addAttribute(XmppAttribute('jid', rosterItem.jid!.userAtDomain));
    if (rosterItem.name != null) {
      itemElement.addAttribute(XmppAttribute('name', rosterItem.name!));
    }
    _myUnrespondedIqStanzas[iqStanza.id!] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  Future<IqStanzaResult> removeRosterItem(Buddy rosterItem) {
    var completer = Completer<IqStanzaResult>();
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var queryElement = XmppElement('query');
    queryElement.addAttribute(XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(queryElement);
    var itemElement = XmppElement('item');
    queryElement.addChild(itemElement);
    itemElement
        .addAttribute(XmppAttribute('jid', rosterItem.jid!.userAtDomain));
    itemElement.addAttribute(XmppAttribute('subscription', 'remove'));
    _myUnrespondedIqStanzas[iqStanza.id!] = Tuple2(iqStanza, completer);
    ;
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  RosterManager(Connection connection) {
    _connection = connection;
    _xmppConnectionStateSubscription =
        connection.connectionStateStream.listen(_connectionStateProcessor);
    _abstractStanzaSubscription =
        connection.inStanzasStream.listen(_processStanza);
  }

  void _connectionStateProcessor(XmppConnectionState state) {
    if (state == XmppConnectionState.Ready) {
      queryForRoster();
    } else if (state == XmppConnectionState.Closed) {
      _rosterMap.clear();
      _rosterController.add([]);
    }
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      final unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (unrespondedStanza != null) {
        if (stanza.type == IqStanzaType.RESULT) {
          if (_isFullJidRequest(unrespondedStanza.item1)) {
            _handleFullRosterResponse(stanza);
          } else if (_isRosterSet(unrespondedStanza.item1)) {
            _handleRosterSetSuccessResponse(unrespondedStanza);
          }
        } else if (stanza.type == IqStanzaType.SET) {
          //it is roster push event
          //send result
          _sendRosterPushResult(stanza);
        } else if (stanza.type == IqStanzaType.ERROR) {
          //todo handle error cases
          _handleRosterSetErrorResponse(unrespondedStanza);
        }
      }
    }
  }

  bool _isFullJidRequest(IqStanza iqStanza) {
    return (iqStanza.type == IqStanzaType.GET &&
        (iqStanza.getChild('query')?.children.isEmpty ?? false));
  }

  bool _isRosterSet(IqStanza iqStanza) {
    return (iqStanza.type == IqStanzaType.SET);
  }

  void _fireOnRosterListChanged() {
    var rosterList = _rosterMap.values.toList();
    _rosterController.add(rosterList);
  }

  void _handleFullRosterResponse(IqStanza stanza) {
    var xmppElement = stanza.getChild('query');
    if (xmppElement != null &&
        xmppElement.getNameSpace() == 'jabber:iq:roster') {
      _rosterMap.clear();
      xmppElement.children.forEach((child) {
        if (child.name == 'item') {
          var jid = Jid.fromFullJid(child.getAttribute('jid')!.value!);
          var name = child.getAttribute('name')?.value;
          var subscriptionString = child.getAttribute('subscription')?.value;
          var buddy = Buddy(jid);
          buddy.name = name;
          buddy.accountJid = _connection.fullJid;
          buddy.subscriptionType = Buddy.typeFromString(subscriptionString);
          _rosterMap[jid] = buddy;
        }
      });
      _fireOnRosterListChanged();
    }
  }

  void _sendRosterPushResult(IqStanza stanza) {
    var iqStanza = IqStanza(stanza.id, IqStanzaType.RESULT);
    iqStanza.fromJid = _connection.fullJid;
    _connection.writeStanza(iqStanza);
  }

  void _handleRosterSetSuccessResponse(Tuple2<IqStanza, Completer?> request) {
    request.item2!.complete(IqStanzaResult()..type = IqStanzaType.SET);
    _myUnrespondedIqStanzas.remove(request.item1.id);
  }

  //todo add error description
  void _handleRosterSetErrorResponse(Tuple2<IqStanza, Completer?> request) {
    request.item2!.complete(IqStanzaResult()
      ..type = IqStanzaType.ERROR
      ..description = '');
    _myUnrespondedIqStanzas.remove(request.item1.id);
  }
}
