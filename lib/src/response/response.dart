import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

class ResponseHandler<T> {
  final Map<String?, Tuple3<T, Completer, dynamic>> _queuedStanzas =
      <String?, Tuple3<T, Completer, dynamic>>{};

  Future<P> set<P>(String id, T stanza, {String description = ''}) {
    final completer = Completer<P>();

    _queuedStanzas[id] = Tuple3(stanza, completer, P);
    return completer.future.timeout(Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
            'Error: ${getResponseMetaData(P.runtimeType.toString(), description: description)} - Request Timeout\n\nStack Detail: ${(stanza as AbstractStanza).buildXmlString()}'));
  }

  void unset(String id) {
    if (_queuedStanzas.containsKey(id)) {
      _queuedStanzas.remove(id);
    }
  }

  void test(String id, callback(Tuple3<T, Completer, dynamic> item)) {
    if (_queuedStanzas.containsKey(id)) {
      callback(_queuedStanzas[id]!);
      unset(id);
    }
  }

  Iterable<String> keys() => _queuedStanzas.keys.map((e) => e ?? "");

  String getResponseMetaData(String responseType, {String description = ''}) {
    return '${responseType}' + (description.isEmpty ? '' : ' - $description');
  }
}
