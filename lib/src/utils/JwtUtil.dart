import 'dart:convert';

import 'package:jose/jose.dart';

enum AuthJwtType { jwk, secret }

const hostName = 'jabber.local';

class JwtUtil {
  String generateToken({
    required String host,
    required String jid,
    required String jsonJwk,
  }) {
    String token;

    var claims = new JsonWebTokenClaims.fromJson({
      "exp": new Duration(days: 10).inSeconds,
      'jid': '${jid}@${host}',
    });

    // create a builder, decoding the JWT in a JWS, so using a
    // JsonWebSignatureBuilder
    var builder = new JsonWebSignatureBuilder();

    // set the content
    builder.jsonContent = claims.toJson();

    final jsonKey = jsonDecode(jsonJwk);

    // add a key to sign, can only add one for JWT
    builder.addRecipient(new JsonWebKey.fromJson(jsonKey), algorithm: "HS256");

    // build the jws
    var jws = builder.build();

    // output the compact serialization
    token = jws.toCompactSerialization();

    return token;
  }
}
