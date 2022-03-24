import '../models/TestUser.dart';

class Preferences {
  Preferences._();

  static const String hostName =
      "jabber.local"; // 'staging.xmpp.hiapp-chat.com';
  static const AuthJwtType authJwtType = AuthJwtType.jwk;
  static const String secret = "hiapp-chat";
  static const String jwtKeyPath = '/example/jwt_key/jwt_key.jwk';
}
