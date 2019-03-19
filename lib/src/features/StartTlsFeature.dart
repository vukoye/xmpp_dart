import 'dart:async';

import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/nonzas/Nonza.dart';
import 'package:xmpp/src/features/Feature.dart';
import 'package:xmpp/xmpp.dart';

class StartTlsFeature extends Feature {

  Connection _connection;

  StreamSubscription<Nonza> subscription;

  StartTlsFeature(Connection connection) {
    _connection = connection;
    expectedName = "starttls";
    expectedNameSpace = "urn:ietf:params:xml:ns:xmpp-tls";
  }

  @override
  void negotiate(Nonza nonza) {
    print('negotiating starttls');
    if (match(nonza)) {
      if (nonza.name == "starttls") {
        state = FeatureState.PARSING;
        subscription = _connection.nonzasStream.listen(checkNonzas);
        _connection.writeNonza(new StartTlsResponse());
      }
    }
  }

  void checkNonzas(Nonza nonza) {
    if (nonza.name == "proceed") {
      state = FeatureState.DONE;
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