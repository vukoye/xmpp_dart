import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/features/error/StreamConflictHandler.dart';
import 'package:xmpp_stone/src/features/error/StreamViolationPolicyHandler.dart';

class ConnectionStreamErrorHandler {
  StreamConflictHandler? streamConflictHandler;
  StreamViolationPolicyHandler? streamViolationPolicyHandler;

  ConnectionStreamErrorHandler.init(Connection connection) {
    streamConflictHandler = StreamConflictHandler(connection);
    streamConflictHandler!.init();
    streamViolationPolicyHandler = StreamViolationPolicyHandler(connection);
    streamViolationPolicyHandler!.init();
  }

  void dispose() {
    streamConflictHandler!.dispose();
    streamViolationPolicyHandler!.dispose();
  }
}
