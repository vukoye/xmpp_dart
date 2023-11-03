import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

import '../logger/Log.dart';

class StartTlsNegotiator extends Negotiator {
  static const TAG = 'StartTlsNegotiator';
  final Connection _connection;
  late StreamSubscription<Nonza> subscription;

  StartTlsNegotiator(this._connection) {
    expectedName = 'StartTlsNegotiator';
    expectedNameSpace = 'urn:ietf:params:xml:ns:xmpp-tls';
    priorityLevel = 1;
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    Log.d(TAG, 'negotiating starttls');
    state = NegotiatorState.NEGOTIATING;
    subscription = _connection.inNonzasStream.listen(checkNonzas);
    _connection.writeNonza(StartTlsResponse());
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
    var nonza = requests.firstWhereOrNull((request) =>
        request.name == 'starttls' &&
        request.getAttribute('xmlns')?.value == expectedNameSpace);
    return nonza != null ? [nonza] : [];
  }
}

class StartTlsResponse extends Nonza {
  StartTlsResponse() : super('starttls') {
    addAttribute(XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-tls'));
  }
}
