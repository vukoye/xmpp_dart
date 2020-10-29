
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import '../../Connection.dart';
import '../../elements/nonzas/Nonza.dart';
import '../Negotiator.dart';
import 'Feature.dart';

class MAMNegotiator extends Negotiator {

  static const TAG = 'MAMNegotiator';

  static final Map<Connection, MAMNegotiator> _instances =
  <Connection, MAMNegotiator>{};


  static MAMNegotiator getInstance(Connection connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = MAMNegotiator(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  // ignore: unused_field
  final Connection _connection;

  bool enabled = false;

  bool hasExtended;

  MAMNegotiator(this._connection) {
    expectedName = 'urn:xmpp:mam';
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return requests.where((element) =>
    element is Feature &&
        ((element).xmppVar == 'urn:xmpp:mam:2' ||
            (element).xmppVar == 'urn:xmpp:mam:2#extended')).toList();
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    if (match(nonzas).isNotEmpty) {
      enabled = true;
      checkForExtendedSupport(nonzas);
      state = NegotiatorState.DONE;
    }
  }

  void checkForExtendedSupport(List<Nonza> nonzas) {
    hasExtended = nonzas.any((element) => (element as Feature).xmppVar == 'urn:xmpp:mam:2#extended');
  }
}
