import 'dart:async';

import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/features/Negotiator.dart';

class StartTlsNegotiator extends ConnectionNegotiator {

  Connection _connection;

  StreamSubscription<Nonza> subscription;

  StartTlsNegotiator(Connection connection) {
    _connection = connection;
    expectedName = "starttls";
    expectedNameSpace = "urn:ietf:params:xml:ns:xmpp-tls";
  }

  @override
  void negotiate(Nonza nonza) {
    print('negotiating starttls');
    if (match(nonza)) {
      if (nonza.name == "starttls") {
        state = NegotiatorState.NEGOTIATING;
        subscription = _connection.nonzasStream.listen(checkNonzas);
        _connection.writeNonza(new StartTlsResponse());
      }
    }
  }

  void checkNonzas(Nonza nonza) {
    if (nonza.name == "proceed") {
      state = NegotiatorState.DONE;
      subscription.cancel();
      _connection.startSecureSocket();
    } else if (nonza.name == "failure") {
      _connection.startTlsFailed();
    }
  }

  @override
  bool match(Nonza request) {
    return (request.name == "starttls") && request.getAttribute('xmlns')?.value == expectedNameSpace;
  }


}

class StartTlsResponse extends Nonza {
  StartTlsResponse() {
    name = "starttls";
    addAttribute(new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-tls'));
  }
}