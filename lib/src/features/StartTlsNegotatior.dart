import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

import '../elements/nonzas/Nonza.dart';
import '../logger/Log.dart';

class StartTlsNegotiator extends Negotiator {
  static const TAG = 'StartTlsNegotiator';
  Connection _connection;
  StreamSubscription<Nonza> subscription;

  StartTlsNegotiator(Connection connection) {
    _connection = connection;
    expectedName = 'StartTlsNegotiator';
    expectedNameSpace = 'urn:ietf:params:xml:ns:xmpp-tls';
    priorityLevel = 1;
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    Log.d(TAG, 'negotiating starttls');
    if (match(nonzas) != null) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inNonzasStream.listen(checkNonzas);
      _connection.writeNonza(StartTlsResponse());
    }
  }

  void checkNonzas(Nonza nonza) {
    if (nonza.name == 'proceed') {
      _connection.startSecureSocket();
      state = NegotiatorState.DONE_CLEAN_OTHERS;
      subscription.cancel();
    } else if (nonza.name == 'failure') {
      _connection.startTlsFailed();
    }
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    var nonza = requests.firstWhere(
        (request) =>
            request.name == 'starttls' &&
            request.getAttribute('xmlns')?.value == expectedNameSpace,
        orElse: () => null);
    return nonza != null ? [nonza] : [];
  }
}

class StartTlsResponse extends Nonza {
  StartTlsResponse() {
    name = 'starttls';
    addAttribute(XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-tls'));
  }
}
