import 'dart:convert';
import 'dart:io';

import '../preferences/preferences.dart';
import '../user.dart';
import 'xmpp_communication_callback.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:jose/jose.dart';

enum AuthJwtType { jwk, secret }

const hostName = 'jabber.local';

class TestUser {
  TestUser();

  Map<String, User> getTestUser() {
    final host = Preferences.hostName;
    Map<String, User> users = {
      '62612223931': User(
          name: 'kevin1',
          password:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjEsInJvbGUiOiJVU0VSIiwidXNlciI6IjYyNjEyMjIzOTMxIiwiaWF0IjoxNjQ3NTcwNTE2LCJleHAiOjMxNzE5MjAxMjkxNn0.m7zBlAf9j-xdPPy1Qugq_cEqC596kmnf-m4DdCWRUSA',
          jid: '62612223931@${host}/kevin1',
          phoneNumber: '62612223931',
          xmppCallback: XmppCommunicationCallback()),
      '62612223932': User(
          name: 'kevin2',
          password:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjUsInJvbGUiOiJVU0VSIiwidXNlciI6IjYyNjEyMjIzOTMyIiwiaWF0IjoxNjQ3NTcyMTIwLCJleHAiOjMxNzE5MjAxNDUyMH0.x2pVGbt5Q9z3ONeUNsz6d3Yu0Gr6Qiru2UWzxQKxkGE',
          jid: '62612223932@${host}/kevin2',
          phoneNumber: '62612223932',
          xmppCallback: XmppCommunicationCallback()),
    };

    return users;
  }
  
  User generateUser(int i) {
    final host = Preferences.hostName;
    final randomUserPhoneNumber = 20000000 + i;
    String token;

    if (Preferences.authJwtType == AuthJwtType.jwk) {
      var claims = new JsonWebTokenClaims.fromJson({
        "exp": new Duration(days: 10).inSeconds,
        'jid': '62${randomUserPhoneNumber}@${host}',
      });

      // create a builder, decoding the JWT in a JWS, so using a
      // JsonWebSignatureBuilder
      var builder = new JsonWebSignatureBuilder();

      // set the content
      builder.jsonContent = claims.toJson();

      final jsonContent =
          File('${Directory.current.path}/${Preferences.jwtKeyPath}')
              .readAsStringSync();
      final jsonKey = jsonDecode(jsonContent);

      // add a key to sign, can only add one for JWT
      builder.addRecipient(new JsonWebKey.fromJson(jsonKey),
          algorithm: "HS256");

      // build the jws
      var jws = builder.build();

      // output the compact serialization
      token = jws.toCompactSerialization();
    } else {
      final jwt = JWT({
        'id': 123,
        'role': 'user',
        'user': '62${randomUserPhoneNumber}',
        'jid': '62${randomUserPhoneNumber}@${host}',
      });

      token = jwt.sign(SecretKey(Preferences.secret),
          expiresIn: Duration(days: 10), algorithm: JWTAlgorithm.HS256);
    }

    final user = User(
        name: randomUserPhoneNumber.toString(),
        password: token,
        jid: '62${randomUserPhoneNumber}@${host}/${i}',
        phoneNumber: randomUserPhoneNumber.toString(),
        xmppCallback: XmppCommunicationCallback());

    return user;
  }

  Map<String, User> generateUsers(int nUser) {
    Map<String, User> users = Map();

    for (var i = 1; i <= nUser; i++) {
      final user = generateUser(i);
      users[user.phoneNumber] = user;
    }

    return users;
  }
}
