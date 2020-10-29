import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cryptoutils/utils.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:xmpp_stone/src/features/sasl/AbstractSaslHandler.dart';
import 'package:xmpp_stone/src/features/sasl/SaslAuthenticationFeature.dart';

import '../../logger/Log.dart';

//https://stackoverflow.com/questions/29298346/xmpp-sasl-scram-sha1-authentication#comment62495063_29299946
class ScramSaslHandler implements AbstractSaslHandler {
  static const CLIENT_NONCE_LENGTH = 48;
  static const TAG = 'ScramSaslHandler';

  Connection _connection;
  StreamSubscription<Nonza> subscription;
  final _completer = Completer<AuthenticationResult>();
  ScramStates _scramState = ScramStates.INITIAL;
  String _password;
  String _username;
  String _clientNonce;
  String _initialMessage;

  final SaslMechanism _mechanism;
  Hash _hash;

  String _mechanismString;

  var serverSignature;

  ScramSaslHandler(Connection connection, String password, this._mechanism) {
    _username = connection.fullJid.local;
    _password = password;
    _connection = connection;
    initMechanism();
    generateRandomClientNonce();
  }

  @override
  Future<AuthenticationResult> start() {
    subscription = _connection.inNonzasStream.listen(_parseAnswer);
    sendInitialMessage();
    return _completer.future;
  }

  void initMechanism() {
    if (_mechanism == SaslMechanism.SCRAM_SHA_1) {
      _hash = sha1;
      _mechanismString = 'SCRAM-SHA-1';
    } else if (_mechanism == SaslMechanism.SCRAM_SHA_256) {
      _hash = sha256;
      _mechanismString = 'SCRAM-SHA-256';
    }
  }

  void generateRandomClientNonce() {
    var bytes = List<int>(CLIENT_NONCE_LENGTH);
    for (var i = 0; i < CLIENT_NONCE_LENGTH; i++) {
      bytes[i] = Random.secure().nextInt(256);
    }
    _clientNonce = base64.encode(bytes);
  }

  void sendInitialMessage() {
    _initialMessage = 'n=${saslEscape(normalize(_username))},r=${_clientNonce}';
    var bytes = utf8.encode('n,,$_initialMessage');
    var message = CryptoUtils.bytesToBase64(bytes, false, false);
    var nonza = Nonza();
    nonza.name = 'auth';
    nonza.addAttribute(
        XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-sasl'));
    nonza.addAttribute(XmppAttribute('mechanism', _mechanismString));
    nonza.textValue = message;
    _scramState = ScramStates.AUTH_SENT;
    _connection.writeNonza(nonza);
  }

  void _parseAnswer(Nonza nonza) {
    if (_scramState == ScramStates.AUTH_SENT) {
      if (nonza.name == 'failure') {
        _fireAuthFailed('Auth Error in sent username');
      } else if (nonza.name == 'challenge') {
        //challenge
        challengeFirst(nonza.textValue);
      }
    } else if (_scramState == ScramStates.RESPONSE_SENT) {
      if (nonza.name == 'failure') {
        _fireAuthFailed('Auth Error in challenge');
      } else if (nonza.name == 'success') {
        verifyServerHasKey(nonza.textValue);
      }
    }
  }

  void _fireAuthFailed(String message) {
    //todo sent auth error message
    Log.e(TAG, message);
    subscription.cancel();
    _completer.complete(AuthenticationResult(false, message));
  }

  static String saslEscape(String input) {
    return input.replaceAll('=', '=2C').replaceAll(',', '=3D');
  }

  static String normalize(String input) {
    return unorm.nfkd(input);
  }

  static List<String> tokenizeGS2header(var list) {
    return utf8.decode(list).split(',').map((i) => i.trim()).toList();
  }

  void challengeFirst(String content) {
    var serverFirstMessage = base64.decode(content);
    var tokens = tokenizeGS2header(serverFirstMessage);

    var serverNonce = '';
    var iterationsNo = -1;
    var salt = '';
    tokens.forEach((token) {
      if (token[1] == '=') {
        switch (token[0]) {
          case 'i':
            try {
              iterationsNo = int.parse(token.substring(2));
            } catch (e) {
              _fireAuthFailed(
                  'Unable to parse iteration number ${token.substring(2)}');
              return;
            }
            break;
          case 's':
            salt = token.substring(2);
            break;
          case 'r':
            serverNonce = token.substring(2);
            break;
          case 'm':
            _fireAuthFailed('Server sent m token!');
            break;
        }
      }
    });
    if (iterationsNo < 0) {
      _fireAuthFailed('No iterations number received');
      return;
    }
    if (serverNonce.isEmpty || !serverNonce.startsWith(_clientNonce)) {
      _fireAuthFailed('Server nonce not same as client nonce');
      return;
    }
    if (salt.isEmpty) {
      _fireAuthFailed('Salt not sent');
    }
    var clientFinalMessageBare = 'c=biws,r=$serverNonce';
    //ok
    var authMessage = utf8.encode(
        '$_initialMessage,${utf8.decode(serverFirstMessage)},$clientFinalMessageBare');
    var saltB = base64.decode(salt);
    var saltedPassword = PBKDF2(utf8.encode(_password), saltB, iterationsNo);
    var serverKey = hmac(saltedPassword, utf8.encode('Server Key'));
    var clientKey = hmac(saltedPassword, utf8.encode('Client Key'));
    List<int> clientSignature;
    try {
      serverSignature = hmac(serverKey, authMessage);
      var storedKey = _hash.convert(clientKey).bytes;
      clientSignature = hmac(storedKey, authMessage);
    } catch (e) {
      _fireAuthFailed('Invalid key');
    }
    var clientProof = List<int>(clientKey.length);
    for (var i = 0; i < clientKey.length; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }
    var clientFinalMessage =
        '$clientFinalMessageBare,p=${base64.encode(clientProof)}';
    var response = Nonza();
    response.name = 'response';
    response.addAttribute(
        XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-sasl'));
    response.textValue = base64.encode(utf8.encode(clientFinalMessage));
    _scramState = ScramStates.RESPONSE_SENT;
    _connection.writeNonza(response);
  }

  List<int> hmac(List<int> key, List<int> input) {
    var hmac = crypto.Hmac(_hash, key);
    return hmac.convert(input).bytes;
  }

  List<int> PBKDF2(List<int> password, List<int> salt, int c) {
    var u = hmac(password, salt + [0, 0, 0, 1]);
    var out = List<int>.from(u);
    for (var i = 1; i < c; i++) {
      u = hmac(password, u);
      for (var j = 0; j < u.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  void verifyServerHasKey(String serverResponse) {
    var expectedServerFinalMessage = 'v=${base64.encode(serverSignature)}';
    if (utf8.decode(base64.decode(serverResponse)) !=
        expectedServerFinalMessage) {
      _fireAuthFailed('Server final message does not match expected one');
    } else {
      subscription.cancel();
      _completer.complete(AuthenticationResult(true, ''));
    }
  }
}

enum ScramStates {
  INITIAL,
  AUTH_SENT,
  RESPONSE_SENT,
}
