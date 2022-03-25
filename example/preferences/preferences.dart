import '../models/TestUser.dart';

class Preferences {
  Preferences._();

  static const String hostName =
      'staging.xmpp.hiapp-chat.com'; // "jabber.local"; //
  static const AuthJwtType authJwtType = AuthJwtType.secret;
  static const String secret = "hiapp-chat";
  static const String jwtKeyPath = '/example/jwt_key/jwt_key.jwk';
}
