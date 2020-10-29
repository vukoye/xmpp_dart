import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/extensions/vcard_temp/VCard.dart';

class VCardManager {
  static Map<Connection, VCardManager> instances =
      <Connection, VCardManager>{};

  static VCardManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = VCardManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  final Connection _connection;

  VCardManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  final Map<String, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
      <String, Tuple2<IqStanza, Completer>>{};

  final Map<String, VCard> _vCards = <String, VCard>{};

  Future<VCard> getSelfVCard() {
    var completer = Completer<VCard>();
    var iqStanza =
        IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    iqStanza.addChild(vCardElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  Future<VCard> getVCardFor(Jid jid) {
    var completer = Completer<VCard>();
    var iqStanza =
        IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = jid;
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    iqStanza.addChild(vCardElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  void _connectionStateProcessor(XmppConnectionState event) {}

  Map<String, VCard> getAllReceivedVCards() {
    return _vCards;
  }

  void _processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
      if (_myUnrespondedIqStanzas[stanza.id] != null) {
        if (stanza.type == IqStanzaType.RESULT) {
          var vCardChild = stanza.getChild('vCard');
          if (vCardChild != null) {
            var vCard = VCard(vCardChild);
            if (stanza.fromJid != null) {
              _vCards[stanza.fromJid.userAtDomain] = vCard;
            } else {
              _vCards[_connection.fullJid.userAtDomain] = vCard;
            }
            unrespondedStanza.item2.complete(vCard);
          }
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedStanza.item2
              .complete(InvalidVCard(stanza.getChild('vCard')));
        }
      }
    }
  }
}
