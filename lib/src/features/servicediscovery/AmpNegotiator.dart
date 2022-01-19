import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

import '../../../xmpp_stone.dart';
import '../../Connection.dart';
import '../../elements/nonzas/Nonza.dart';
import '../Negotiator.dart';
import 'Feature.dart';

class AmpNegotiator extends Negotiator {
  static const TAG = 'AmpNegotiator';

  static final Map<Connection?, AmpNegotiator> _instances =
      <Connection?, AmpNegotiator>{};

  static AmpNegotiator getInstance(Connection? connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = AmpNegotiator();
      _instances[connection] = instance;
    }
    return instance;
  }

  bool enabled = true;

  AmpNegotiator() {
    expectedName = 'http://jabber.org/protocol/amp';
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return (requests.where((element) =>
        element != null &&
        element is Feature &&
        ((element).xmppVar == expectedName))).toList();
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    // Do not genetiate
    state = NegotiatorState.DONE;
    enabled = true;
  }
}
