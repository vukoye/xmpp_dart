import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/sasl/AbstractSaslHandler.dart';
import 'package:xmpp_stone/src/features/sasl/SaslAuthenticationFeature.dart';

import '../../logger/Log.dart';

class AnonymousHandler implements AbstractSaslHandler {
  static const TAG = 'AnonymousHandler';

  final Connection _connection;
  late StreamSubscription<Nonza> subscription;
  final _completer = Completer<AuthenticationResult>();
  ScramStates _scramState = ScramStates.INITIAL;

  final SaslMechanism _mechanism;

  String? _mechanismString;

  late var serverSignature;

  AnonymousHandler(this._connection, this._mechanism) {
    initMechanism();
  }

  @override
  Future<AuthenticationResult> start() {
    subscription = _connection.inNonzasStream.listen(_parseAnswer);
    sendInitialMessage();
    return _completer.future;
  }

  void initMechanism() {
    if (_mechanism == SaslMechanism.ANONYMOUS) {
      _mechanismString = 'ANONYMOUS';
    }
  }

  void sendInitialMessage() {
    var nonza = Nonza();
    nonza.name = 'auth';
    nonza.addAttribute(
        XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-sasl'));
    nonza.addAttribute(XmppAttribute('mechanism', _mechanismString));
    _scramState = ScramStates.AUTH_SENT;
    _connection.writeNonza(nonza);
  }

  void _parseAnswer(Nonza nonza) {
    if (_scramState == ScramStates.AUTH_SENT) {
      if (nonza.name == 'failure') {
        _fireAuthFailed('Auth Error in challenge');
      } else if (nonza.name == 'success') {
        subscription.cancel();
        _completer.complete(AuthenticationResult(true, ''));
      }
    }
  }

  void _fireAuthFailed(String message) {
    Log.e(TAG, message);
    subscription.cancel();
    _completer.complete(AuthenticationResult(false, message));
  }
}

enum ScramStates {
  INITIAL,
  AUTH_SENT,
}
