import 'dart:async';

import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

abstract class Negotiator {
  static int defaultPriorityLevel = 1000;

  String _expectedName;
  String _expectedNameSpace;
  NegotiatorState _state = NegotiatorState.IDLE;
  int priorityLevel = defaultPriorityLevel;

  NegotiatorState get state => _state;

  StreamController<NegotiatorState> negotiatorStateStreamController =
      StreamController<NegotiatorState>.broadcast();

  Stream<NegotiatorState> get featureStateStream {
    return negotiatorStateStreamController.stream;
  }

  set state(NegotiatorState value) {
    _state = value;
    negotiatorStateStreamController.add(state);
  }

  String get expectedNameSpace => _expectedNameSpace;

  set expectedNameSpace(String value) {
    _expectedNameSpace = value;
  }

  String get expectedName => _expectedName;

  set expectedName(String value) {
    _expectedName = value;
  }

  //goes trough all features and match only needed nonzas
  List<Nonza> match(List<Nonza> request);

  void negotiate(List<Nonza> nonza);

  void backToIdle() {
    state = NegotiatorState.IDLE;
  }

  bool isReady() {
    return _state != NegotiatorState.DONE && state != NegotiatorState.DONE_CLEAN_OTHERS;
  }

  @override
  String toString() {
    return '{name: ${expectedName}, name_space: ${expectedNameSpace}, priority: ${priorityLevel}, state: ${state}}, isReady: ${isReady()}';
  }
}

enum NegotiatorState { IDLE, NEGOTIATING, DONE, DONE_CLEAN_OTHERS }
