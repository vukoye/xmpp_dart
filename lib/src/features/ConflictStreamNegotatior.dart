import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/StreamConflictNonza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

import '../elements/nonzas/Nonza.dart';
import '../logger/Log.dart';

class StreamConflict extends Negotiator {
  static const TAG = 'StreamConflict';
  Connection? _connection;
  late StreamSubscription<Nonza> subscription;

  StreamConflict(Connection? connection) {
    _connection = connection;
    expectedName = 'StreamConflict';
    expectedNameSpace = 'urn:ietf:params:xml:ns:xmpp-streams';
    priorityLevel = 1;
  }

  @override
  void negotiate(List<Nonza> nonzas) {
    Log.d(TAG, 'checking stream conflict');
    if (match(nonzas) != null) {
      subscription = _connection!.inNonzasStream.listen(checkNonzas);
    }
  }

  void checkNonzas(Nonza nonza) {
    _connection!.streamConflict();
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return requests
        .where((element) => StreamConflictNonza.match(element))
        .toList();
  }
}
