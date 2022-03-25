import '../models/TestUser.dart';

class Preferences {
  Preferences._();

  static const String hostName =
      'staging.xmpp.hiapp-chat.com'; // "dev.ejabberd.xmpp.hiapp-chat.com"; //
  static const AuthJwtType authJwtType = AuthJwtType.secret;
  static const String secret = "hiapp-chat";
  static const String jwtKeyPath = '/example/jwt_key/jwt_key.jwk';
//   static const String hostName =
//       "dev.ejabberd.xmpp.hiapp-chat.com"; //  'staging.xmpp.hiapp-chat.com'; //
//   static const AuthJwtType authJwtType = AuthJwtType.jwk;
//   static const String secret = "hiapp-chat";
//   static const String jwtKeyPath = '/example/jwt_key/jwt_key.jwk';

}
