import 'dart:async';

import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

import '../../../xmpp_stone.dart';
import '../../Connection.dart';
import '../../elements/XmppAttribute.dart';
import '../../elements/XmppElement.dart';
import '../../elements/nonzas/Nonza.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../Negotiator.dart';
import 'Feature.dart';

class CarbonsNegotiator extends Negotiator {

  static const TAG = 'CarbonsNegotiator';

  static final Map<Connection, CarbonsNegotiator> _instances =
      <Connection, CarbonsNegotiator>{};


  static CarbonsNegotiator getInstance(Connection connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = CarbonsNegotiator(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  final Connection _connection;

  bool enabled = false;

  StreamSubscription<AbstractStanza> _subscription;
  IqStanza _myUnrespondedIqStanza;

  CarbonsNegotiator(this._connection) {
    expectedName = 'urn:xmpp:carbons';
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return (requests.where((element) =>
        element != null && element is Feature &&
        ((element).xmppVar == 'urn:xmpp:carbons:2' ||
            (element).xmppVar == 'urn:xmpp:carbons:rules:0'))).toList();
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    if (match(nonzas).isNotEmpty) {
      state = NegotiatorState.NEGOTIATING;
      sendRequest();
      _subscription= _connection.inStanzasStream.listen(checkStanzas);
    }
  }

  void sendRequest() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    iqStanza.addAttribute(XmppAttribute('xmlns', 'jabber:client'));
    var element = XmppElement();
    element.name = 'enable';
    element.addAttribute(XmppAttribute('xmlns', 'urn:xmpp:carbons:2'));
    iqStanza.addChild(element);
    _myUnrespondedIqStanza = iqStanza;
    _connection.writeStanza(iqStanza);
  }

  void checkStanzas(AbstractStanza stanza) {
    if (stanza is IqStanza && stanza.id == _myUnrespondedIqStanza.id) {
      enabled = stanza.type == IqStanzaType.RESULT;
      state = NegotiatorState.DONE;
      _subscription.cancel();
    }
  }
}
