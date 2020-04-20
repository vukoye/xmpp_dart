abstract class AbstractSaslHandler {
  Future<AuthenticationResult> start();
}

class AuthenticationResult {
  bool successful;
  String message;

  AuthenticationResult(this.successful, this.message);
}
