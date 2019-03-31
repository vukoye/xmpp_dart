import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptoutils/utils.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:xmppstone/src/features/sasl/SaslAuthenticationFeature.dart';
import 'package:xmppstone/src/features/sasl/pbkdf2/pbkdf2.dart';


//https://stackoverflow.com/questions/29298346/xmpp-sasl-scram-sha1-authentication#comment62495063_29299946
class ScramSha1SaslHandler {
  static const CLIENT_NONCE_LENGTH = 48;
  Connection _connection;
  StreamSubscription<Nonza> subscription;
  var _completer = new Completer<bool>();

  ScramSha1States _scramSha1State = ScramSha1States.INITIAL;

  String _password;

  String _normalizedPassword;

  String _username;

  String _clientNonce;

  String _initialMessage;

  SaslMechanism _mechanism;
  String _mechanismString;

  var serverSignature;

  ScramSha1SaslHandler(
      Connection connection, String password, this._mechanism) {
    _username = connection.fullJid.local;
    _password = password;
    _connection = connection;
    _mechanismString = _mechanism == SaslMechanism.SCRAM_SHA_1 ? "SCRAM-SHA-1" : "SCRAM-SHA-1-PLUS";
    generateRandomClientNonce();
  }

  Future<bool> start() {
    subscription = _connection.nonzasStream.listen(_parseAnswer);
    sendInitialMessage();
    return _completer.future;
  }

  String generateRandomClientNonce() {
    List<int> bytes = List<int>(CLIENT_NONCE_LENGTH);
    for (int i = 0; i < CLIENT_NONCE_LENGTH;i++) {
      bytes[i] = Random.secure().nextInt(256);
    }
    _clientNonce = base64.encode(bytes);
  }

  void sendInitialMessage() {
    _initialMessage = "n=${saslEscape(normalize(_username))},r=${_clientNonce}";
    var bytes = utf8.encode("n,,$_initialMessage");
    var message = CryptoUtils.bytesToBase64(bytes, false, false);
    Nonza nonza = new Nonza();
    nonza.name = "auth";
    nonza.addAttribute(
        new XmppAttribute('xmlns', 'urn:ietf:params:xml:ns:xmpp-sasl'));
    nonza.addAttribute(new XmppAttribute('mechanism', _mechanismString));
    nonza.textValue = message;
    _scramSha1State = ScramSha1States.AUTH_USERNAME_SENT;
    _connection.writeNonza(nonza);
  }

  void _parseAnswer(Nonza nonza) {
    if (_scramSha1State == ScramSha1States.AUTH_USERNAME_SENT) {
      if (nonza.name == 'failure') {
        _fireAuthFailed("Auth Error in sent username");
      } else if (nonza.name == 'challenge') {
        //challenge
        challengeFirst(nonza.textValue);
      }
    } else if (_scramSha1State == ScramSha1States.RESPONSE_SENT) {
      if (nonza.name == 'failure') {
        _fireAuthFailed("Auth Error in challenge");
      } else if (nonza.name == 'success') {
        verifyServerHasKey(nonza.textValue);
      }

    }
  }

  void _fireAuthFailed(String message) {
    //todo sent auth error message
    print(message);
    subscription.cancel();
    _completer.complete(false);
  }

  static saslEscape(String input) {
    return input.replaceAll('=', '=2C').replaceAll(',', '=3D');
  }

  static normalize(String input) {
    return unorm.nfkd(input);
  }

  static List<String> tokenizeGS2header(var list) {
    return utf8.decode(list).split(',').map((i) => i.trim()).toList();
  }

  void challengeFirst(String content) {
    var serverFirstMessage = base64.decode(content);
    var tokens = tokenizeGS2header(serverFirstMessage);
    print("tokens:${tokens}");
    String serverNonce = "";
    int iterationsNo = -1;
    String salt = "";
    tokens.forEach((token) {
      if (token[1] == "=") {
        switch (token[0]) {
          case 'i':
            try {
              iterationsNo = int.parse(token.substring(2));
            } catch (e) {
              _fireAuthFailed(
                  "Unable to parse iteration number ${token.substring(2)}");
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
            _fireAuthFailed("Server sent m token!");
            break;
        }
      }
    });
    if (iterationsNo < 0) {
      _fireAuthFailed("No iterations number received");
      return;
    }
    if (serverNonce.isEmpty || !serverNonce.startsWith(_clientNonce)) {
      _fireAuthFailed("Server nonce not same as client nonce");
      return;
    }
    if (salt.isEmpty) {
      _fireAuthFailed("Salt not sent");
    }
  print("salt=$salt");
  print("iterations=$iterationsNo");
  print("server=$serverNonce");


    String clientFinalMessageBare = "c=biws,r=$serverNonce";
    //ok
    List<int> authMessage = utf8.encode("$_initialMessage,${utf8.decode(serverFirstMessage)},$clientFinalMessageBare");
    var normalizedPassword = CryptoUtils.hexToBytes(CryptoUtils.bytesToHex(utf8.encode(_password)));
    var saltB = base64.decode(salt);
    var saltedPassword = PBKDFx(_password, saltB, iterationsNo);
    var serverKey = hmac(saltedPassword, utf8.encode('Server Key'));
    var clientKey = hmac(saltedPassword, utf8.encode('Client Key'));
    List<int> clientSignature;
    try {
      serverSignature = hmac(serverKey, authMessage);
      var storedKey = crypto.Digest(clientKey);
      clientSignature = hmac(storedKey.bytes, authMessage);
    } catch (e) {
      _fireAuthFailed("Invalid key");
    }
    List<int> clientProof = List<int>(clientKey.length);
    for (int i = 0; i < clientKey.length; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }
    var clientFinalMessage = "$clientFinalMessageBare,p=${base64.encode(clientProof)}";
    var response = Nonza();
    response.name = "response";
    response.addAttribute(XmppAttribute("xmlns", "urn:ietf:params:xml:ns:xmpp-sasl"));
    response.textValue = base64.encode(utf8.encode(clientFinalMessage));
    _scramSha1State = ScramSha1States.RESPONSE_SENT;
    _connection.writeNonza(response);
  }

  List<int> xPBKDF2(List<int> password, List<int> salt, int c) {
    var hmac = crypto.Hmac(crypto.sha1, password);
    crypto.Digest digest = hmac.convert(salt + [0,0,0,1]);
    var u = digest.bytes;
    var out = List<int>.from(u);
    for (int i = 1; i < c; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < u.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  List<int> hmac(List<int> key, List<int> input) {
    var hmac = crypto.Hmac(crypto.sha1, key);
    DigestChunkedConversionSink sink = DigestChunkedConversionSink();
    return hmac.convert(input).bytes;
    //sink.close();
    //outsink.close();
    //return sink.getAll();
  }

  List<int> PBKDFx(String password, List<int> salt, int c) {
    var u = hmac(utf8.encode(password), salt + [0,0,0,1]);
    var out = List<int>(u.length);
    var pb = PBKDF2(hashAlgorithm: crypto.sha1);
    return pb.generateKey(password, salt, c, u.length);



//    for (int i = 1; i < c; i++) {
//      u = hmac(password, u);
//      for (int j = 0; j < u.length; j++) {
//        out[j] ^= u[j];
//      }
//    }
//    return out;
  }

  void verifyServerHasKey(String serverResponse) {
    String expectedServerFinalMessage = "v=${base64.encode(serverSignature)}";
    if (serverResponse != expectedServerFinalMessage) {
      _fireAuthFailed("Server final message does not match expected one");
    } else {
      subscription.cancel();
      _completer.complete(true);
    }
  }
}

class DigestChunkedConversionSink extends ChunkedConversionSink<crypto.Digest> {
  final List<crypto.Digest> accumulated = <crypto.Digest>[];

  @override
  void add(crypto.Digest chunk) {
    accumulated.add(chunk);
  }

  @override
  void close() {}

  List<int> getAll() =>
      accumulated.fold([], (acc, current) => acc..addAll(current.bytes));
}


enum ScramSha1States {
  INITIAL,
  AUTH_USERNAME_SENT,
  RESPONSE_SENT,
  VALID_SERVER_RESPONSE,
}
