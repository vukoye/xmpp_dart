import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

class StartTlsNegotiator extends ConnectionNegotiator {
  Connection _connection;

  StreamSubscription<Nonza> subscription;

  StartTlsNegotiator(Connection connection) {
    _connection = connection;
    expectedName = "starttls";
    expectedNameSpace = "urn:ietf:params:xml:ns:xmpp-tls";
    priorityLevel = 1;
  }

  @override
  void negotiate(Nonza nonza) {
    print('negotiating starttls');
    if (match(nonza)) {
      if (nonza.name == "starttls") {
        state = NegotiatorState.NEGOTIATING;
        subscription = _connection.inNonzasStream.listen(checkNonzas);
        _connection.writeNonza(StartTlsResponse());
      }
    }
  }

  void checkNonzas(Nonza nonza) {
    if (nonza.name == "proceed") {
      _connection.startSecureSocket();
      state = NegotiatorState.DONE_CLEAN_OTHERS;
      subscription.cancel();
    } else if (nonza.name == "failure") {
      _connection.startTlsFailed();
    }
  }

  @override
  bool match(Nonza request) {
    return (request.name == "starttls") &&
        request.getAttribute('xmlns')?.value == expectedNameSpace;
  }
}

class StartTlsResponse extends Nonza {
  StartTlsResponse() {
    name = "starttls";
    addAttribute(XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-tls'));
  }
}
