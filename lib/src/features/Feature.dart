
import 'dart:async';

import 'package:xmpp/src/elements/nonzas/Nonza.dart';

abstract class Feature {
  String _expectedName;
  String _expectedNameSpace;
  FeatureState _state = FeatureState.IDLE;

  FeatureState get state => _state;

  StreamController<FeatureState> featureStateStreamController = new StreamController();

  Stream<FeatureState> get featureStateStream {
    return featureStateStreamController.stream;
  }

  set state(FeatureState value) {
    _state = value;
    featureStateStreamController.add(state);
    if (state == FeatureState.DONE) {
      featureStateStreamController.close();
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

enum FeatureState {
  IDLE, PARSING, DONE
}