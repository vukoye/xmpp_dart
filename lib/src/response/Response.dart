import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/exception/XmppException.dart';
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

class ResponseHandler<T> {
  static int responseTimeoutMs = 30000;

  static StreamController<BaseResponse>? _responseStreamController;
  static setResponseStream(
      StreamController<BaseResponse> responseStreamController) {
    _responseStreamController = responseStreamController;
  }

  final Map<String?, Tuple3<T, Completer, dynamic>> _queuedStanzas =
      <String?, Tuple3<T, Completer, dynamic>>{};

  Future<P> set<P>(String id, T stanza, {String description = ''}) {
    final completer = Completer<P>();

    _queuedStanzas[id] = Tuple3(stanza, completer, P);
    return completer.future.timeout(Duration(milliseconds: responseTimeoutMs),
        onTimeout: () => throw TimeoutException(
            'Error: ${getResponseMetaData(P.runtimeType.toString(), description: description)} - Request Timeout\n\nStack Detail: ${(stanza as AbstractStanza).buildXmlString()}'));
  }

  Future<Stream<BaseResponse>> setStream<P>(String id, T stanza,
      {String description = ''}) {
    final completer = Completer<BaseResponse>();

    _queuedStanzas[id] = Tuple3(stanza, completer, P);

    completer.future.then((value) {
      Log.d('ResponseHandler',
          'Write: ${getResponseMetaData(P.runtimeType.toString(), description: description)}}');
      if (_responseStreamController != null) {
        _responseStreamController!.add(value);
      } else {
        Log.e('ResponseHandler',
            'WriteError: No stream controller; ${getResponseMetaData(P.runtimeType.toString(), description: description)} - \nStack Detail: ${(stanza as AbstractStanza).buildXmlString()}');
      }
    }, onError: (error, stackTrace) {
      Log.e('ResponseHandler',
          'WriteError: Error in completing future; Error: $error; ${getResponseMetaData(P.runtimeType.toString(), description: description)} - \nTrace: $stackTrace\nStack Detail: ${(stanza as AbstractStanza).buildXmlString()}');
      return ResponseException();
    });
    return Future.value(_responseStreamController!.stream);
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
