import 'dart:async';

import 'package:tuple/tuple.dart';

class ResponseHandler<T> {
  final Map<String?, Tuple3<T, Completer, dynamic>> _myUnrespondedIqStanzas =
      <String?, Tuple3<T, Completer, dynamic>>{};

  Future<P> set<P>(String id, T stanza) {
    final completer = Completer<P>();

    _myUnrespondedIqStanzas[id] = Tuple3(stanza, completer, P);
    return completer.future.timeout(Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Requst is timeout'));
  }

  void unset(String id) {
    if (_myUnrespondedIqStanzas.containsKey(id)) {
      _myUnrespondedIqStanzas.remove(id);
    }
  }

  void test(String id, callback(Tuple3<T, Completer, dynamic> item)) {
    if (_myUnrespondedIqStanzas.containsKey(id)) {
      callback(_myUnrespondedIqStanzas[id]!);
      unset(id);
    }
  }

  Iterable<String> keys() => _myUnrespondedIqStanzas.keys.map((e) => e ?? "");
}
