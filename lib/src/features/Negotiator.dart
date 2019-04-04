
import 'dart:async';

import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

abstract class ConnectionNegotiator {
  String _expectedName;
  String _expectedNameSpace;
  NegotiatorState _state = NegotiatorState.IDLE;

  NegotiatorState get state => _state;

  StreamController<NegotiatorState> negotiatorStateStreamController = new StreamController();

  Stream<NegotiatorState> get featureStateStream {
    return negotiatorStateStreamController.stream;
  }

  set state(NegotiatorState value) {
    _state = value;
    negotiatorStateStreamController.add(state);
    if (state == NegotiatorState.DONE) {
      negotiatorStateStreamController.close();
    }
  }

  String get expectedNameSpace => _expectedNameSpace;

  set expectedNameSpace(String value) {
    _expectedNameSpace = value;
  }

  String get expectedName => _expectedName;

  set expectedName(String value) {
    _expectedName = value;
  }

  bool match(Nonza request);

  void negotiate(Nonza nonza);
}

enum NegotiatorState {
  IDLE, NEGOTIATING, DONE
}