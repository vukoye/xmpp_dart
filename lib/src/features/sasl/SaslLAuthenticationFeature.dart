import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/features/Negotiator.dart';
import 'package:xmppstone/src/features/sasl/PlainSaslHandler.dart';

class SaslAuthenticationFeature extends ConnectionNegotiator {
  Connection _connection;

  Set<SaslMechanism> _offeredMechanisms = new Set<SaslMechanism>();
  Set<SaslMechanism> _supportedMechanisms = new Set<SaslMechanism>();

  String _password;

  SaslAuthenticationFeature(Connection connection, String password) {
    _password = password;
    _connection = connection;
    _supportedMechanisms.add(SaslMechanism.PLAIN);
  }

  // improve this
  @override
  bool match(Nonza request) {
    return request.name == "mechanisms";
  }

  @override
  void negotiate(Nonza nonza) {
    _populateOfferedMechanism(nonza);
    _process();
  }
  void _process() {
    var mechanism = _supportedMechanisms.firstWhere((mechanism) => _supportedMechanisms.contains(mechanism), orElse: _handleAuthNotSupported);
    if (mechanism == SaslMechanism.PLAIN) {
      state = NegotiatorState.NEGOTIATING;
      PlainSaslHandler plainSaslHandler = new PlainSaslHandler(_connection, _password);
      plainSaslHandler.start().then((result ) {
        if (result) {
          _connection.setState(XmppConnectionState.Authenticated);
        } else {
          _connection.setState(XmppConnectionState.AuthenticationFailure);
          _connection.close();
        }
        state = NegotiatorState.DONE;
      });
    }
  }

  void _populateOfferedMechanism(Nonza nonza) {
    nonza.children
        .where((element) => element.name == "mechanism")
        .forEach((mechanism) {
      switch (mechanism.textValue) {
        case "EXTERNAL":
          _offeredMechanisms.add(SaslMechanism.EXTERNAL);
          break;
        case "SCRAM-SHA-1-PLUS":
          _offeredMechanisms.add(SaslMechanism.SCRAM_SHA_1_PLUS);
          break;
        case "SCRAM-SHA-1":
          _offeredMechanisms.add(SaslMechanism.SCRAM_SHA_1);
          break;
        case "PLAIN":
          _offeredMechanisms.add(SaslMechanism.PLAIN);
          break;
      }
    });
  }

  SaslMechanism _handleAuthNotSupported() {
    _connection.setState(XmppConnectionState.AuthenticationNotSuppored);
    _connection.close();
    state = NegotiatorState.DONE;
    return SaslMechanism.NOT_SUPPORTED;
  }
}


enum SaslMechanism { EXTERNAL, SCRAM_SHA_1_PLUS, SCRAM_SHA_1, PLAIN, NOT_SUPPORTED }
