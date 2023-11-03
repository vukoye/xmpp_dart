import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/account/XmppAccountSettings.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/BindingResourceNegotiator.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'package:xmpp_stone/src/features/SessionInitiationNegotiator.dart';
import 'package:xmpp_stone/src/features/StartTlsNegotatior.dart';
import 'package:xmpp_stone/src/features/sasl/SaslAuthenticationFeature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/CarbonsNegotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Feature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoveryNegotiator.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';

import '../logger/Log.dart';

class ConnectionNegotiatorManager {
  static const String TAG = 'ConnectionNegotiatorManager';
  List<Negotiator> supportedNegotiatorList = [];
  Negotiator? activeNegotiator;
  Queue<NegotiatorWithSupportedNonzas?> waitingNegotiators =
      Queue<NegotiatorWithSupportedNonzas?>();

  final Connection _connection;
  final XmppAccountSettings _accountSettings;

  StreamSubscription<NegotiatorState>? activeSubscription;

  ConnectionNegotiatorManager(this._connection, this._accountSettings);

  void init() {
    supportedNegotiatorList.clear();
    _initSupportedNegotiatorList();
    waitingNegotiators.clear();
  }

  void negotiateFeatureList(xml.XmlElement element) {
    Log.d(TAG, 'Negotiating features');
    var nonzas =
        element.childElements.map((element) => Nonza.parse(element)).toList();
    supportedNegotiatorList.forEach((negotiator) {
      var matchingNonzas = negotiator.match(nonzas);
      if (matchingNonzas?.isNotEmpty == true) {
        waitingNegotiators
            .add(NegotiatorWithSupportedNonzas(negotiator, matchingNonzas!));
      }
    });
    if (_connection.authenticated) {
      waitingNegotiators.add(NegotiatorWithSupportedNonzas(
          ServiceDiscoveryNegotiator.getInstance(_connection), []));
    }
    _negotiateNextFeature();
  }

  void _cleanNegotiators() {
    waitingNegotiators.clear();
    if (activeNegotiator != null) {
      activeNegotiator!.backToIdle();
      activeNegotiator = null;
    }
    if (activeSubscription != null) {
      activeSubscription!.cancel();
    }
  }

  void _negotiateNextFeature() {
    var negotiatorWithData = _pickNextNegotiator();
    if (negotiatorWithData != null) {
      activeNegotiator = negotiatorWithData.negotiator;
      activeNegotiator!.negotiate(negotiatorWithData.supportedNonzas);
      //TODO: this should be refactored
      if (activeSubscription != null) activeSubscription!.cancel();
      if (activeNegotiator != null) {
        Log.d(TAG, 'ACTIVE FEATURE: ${negotiatorWithData.negotiator}');
      }

      try {
        activeSubscription =
            activeNegotiator!.featureStateStream.listen(stateListener);
      } catch (e) {
        // Stream has already been listened to this listener
      }
    } else {
      activeNegotiator = null;
      _connection.doneParsingFeatures();
    }
  }

  void _initSupportedNegotiatorList() {
    var streamManagement = StreamManagementModule.getInstance(_connection);
    streamManagement.reset();
    if (_connection.isTlsRequired()) {
      supportedNegotiatorList.add(StartTlsNegotiator(_connection)); //priority 1
    }
    supportedNegotiatorList
        .add(SaslAuthenticationFeature(_connection, _accountSettings.password));
    if (streamManagement.isResumeAvailable()) {
      supportedNegotiatorList.add(streamManagement);
    }
    supportedNegotiatorList
        .add(BindingResourceConnectionNegotiator(_connection));
    supportedNegotiatorList
        .add(streamManagement); //doesn't care if success it will be done
    supportedNegotiatorList.add(SessionInitiationNegotiator(_connection));
    // supportedNegotiatorList
    //     .add(ServiceDiscoveryNegotiator.getInstance(_connection));
    supportedNegotiatorList.add(CarbonsNegotiator.getInstance(_connection));
    supportedNegotiatorList.add(MAMNegotiator.getInstance(_connection));
  }

  void stateListener(NegotiatorState state) {
    if (state == NegotiatorState.NEGOTIATING) {
      Log.d(TAG, 'Feature Started Parsing');
    } else if (state == NegotiatorState.DONE_CLEAN_OTHERS) {
      _cleanNegotiators();
    } else if (state == NegotiatorState.DONE) {
      _negotiateNextFeature();
    }
  }

  NegotiatorWithSupportedNonzas? _pickNextNegotiator() {
    if (waitingNegotiators.isEmpty) return null;
    var negotiatorWithData = waitingNegotiators.firstWhereOrNull((element) {
      Log.d(TAG,
          'Found matching negotiator ${element!.negotiator.isReady().toString()}');
      return element.negotiator.isReady();
    });
    if (negotiatorWithData == null) {
      Log.d(TAG, 'No matching negotiator');
    }
    waitingNegotiators.remove(negotiatorWithData);
    return negotiatorWithData;
  }

  void addFeatures(List<Feature> supportedFeatures) {
    Log.e(TAG,
        'ADDING FEATURES count: ${supportedFeatures.length} $supportedFeatures');
    supportedNegotiatorList.forEach((negotiator) {
      var matchingNonzas = negotiator.match(supportedFeatures);
      if (matchingNonzas != null && matchingNonzas.isNotEmpty) {
        Log.d(TAG, 'Adding negotiator: $negotiator $matchingNonzas');
        waitingNegotiators
            .add(NegotiatorWithSupportedNonzas(negotiator, matchingNonzas));
      }
    });
  }
}

class NegotiatorWithSupportedNonzas {
  Negotiator negotiator;
  List<Nonza> supportedNonzas;

  NegotiatorWithSupportedNonzas(this.negotiator, this.supportedNonzas);
}
