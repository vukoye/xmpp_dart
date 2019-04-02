import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/XmppElement.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/elements/stanzas/IqStanza.dart';
import 'package:xmppstone/src/extensions/vcard_temp/VCard.dart';

class VCardManager {
  static Map<Connection, VCardManager> instances =
  Map<Connection, VCardManager>();

  static getInstance(Connection connection) {
    VCardManager manager = instances[connection];
    if (manager == null) {
      manager = VCardManager(connection);
      instances[connection] = manager;
    }

    return manager;
  }

  Connection _connection;

  VCardManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  Map<String, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas = Map<
      String,
      Tuple2<IqStanza, Completer>>();

  Map<String, VCard> _vCards = Map<String, VCard>();

  Future<VCard> getSelfVCard() {
    var completer = new Completer<VCard>();
    IqStanza iqStanza = IqStanza(
        AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    XmppElement vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    iqStanza.addChild(vCardElement);
    _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
    _connection.writeStanza(iqStanza);
    return completer.future;
  }

  Future<VCard> getVCardFor(Jid jid) {
    var completer = new Completer<VCard>();
    IqStanza iqStanza = IqStanza(
        AbstractStanza.getRandomId(), IqStanzaType.GET);
    iqStanza.fromJid = _connection.fullJid;
    iqStanza.toJid = jid;
    XmppElement vCardElement = XmppElement();
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
          var vCardChild = stanza.getChild("vCard");
          if (vCardChild != null) {
            VCard vCard = VCard(vCardChild);
            if (stanza.fromJid != null) {
              _vCards[stanza.fromJid.userAtDomain] = vCard;
            } else {
              _vCards[_connection.fullJid.userAtDomain] = vCard;
            }
            unrespondedStanza.item2.complete(vCard);
          }
        } else if (stanza.type == IqStanzaType.ERROR) {
          unrespondedStanza.item2.complete(InvalidVCard);
        }
      }
    }
  }
}
