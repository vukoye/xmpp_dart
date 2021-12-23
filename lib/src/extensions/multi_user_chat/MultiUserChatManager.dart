import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChat.dart';

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

  final Map<String?, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String?, Tuple2<IqStanza, Completer>>{};

  final Map<String, MultiUserChat> _mucList = <String, MultiUserChat>{};

  void _connectionStateProcessor(XmppConnectionState event) {}

  Map<String, MultiUserChat> getAllReceivedVCards() {
    return _mucList;
  }

  // Try to discover the services
  Future<MultiUserChat> discoverMucService(Jid mucServiceDomain) {
    var completer = Completer<MultiUserChat>();
    var iqStanza =
        IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = mucServiceDomain;
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));
    iqStanza.addChild(queryElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    print(iqStanza.buildXmlString());
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  MultiUserChat? _handleDiscoverMucServiceResponse(IqStanza stanza) {
    var queryChild = stanza.getChild('query');
    if (queryChild != null) {

      var muc = MultiUserChat();
      muc.mucDomain = stanza.fromJid.toString();
      muc.chatrooms = [];
      muc.features = [];
      queryChild.children
        .where((element) => element!.name == 'feature')
        .forEach((element) {
          muc.features.add(element!.getAttribute('var')!.value);
        });
      queryChild.children
        .where((element) => element!.name == 'Chatrooms')
        .forEach((element) {
          muc.chatrooms.add(MUCChatroom(element!.getAttribute('category')!.value, element.getAttribute('type')!.value, element.getAttribute('name')!.value));
        });
      return muc;
    }
    return null;
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (_myUnrespondedIqStanzas[stanza.id] != null) {
        print('MUC Stanza type: ' + stanza.type.toString());
        if (stanza.type == IqStanzaType.RESULT) {
          var mucResult = _handleDiscoverMucServiceResponse(stanza);
          if (mucResult != null) {
            unrespondedStanza!.item2.complete(mucResult);
          }
          // vCardChild is null because of the result response of updating the card
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedStanza!.item2
              .complete(null);
        }
      }
    }
  }

}
