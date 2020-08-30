import 'dart:async';
import 'dart:collection';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/account/XmppAccountSettings.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/BindingResourceNegotiator.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'package:xmpp_stone/src/features/SessionInitiationNegotiator.dart';
import 'package:xmpp_stone/src/features/StartTlsNegotatior.dart';
import 'package:xmpp_stone/src/features/sasl/SaslAuthenticationFeature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoveryNegotiator.dart';
import 'package:xml/xml.dart' as xml;
import 'package:tuple/tuple.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';

class ConnectionNegotiatorManager {
  List<ConnectionNegotiator> supportedNegotiatorList = <ConnectionNegotiator>[];
  ConnectionNegotiator activeFeature;
  Queue<Tuple2<ConnectionNegotiator, Nonza>> waitingNegotiators =
      Queue<Tuple2<ConnectionNegotiator, Nonza>>();

  Connection _connection;
  XmppAccountSettings _accountSettings;

  StreamSubscription<NegotiatorState> activeSubscription;

  ConnectionNegotiatorManager(Connection connection, XmppAccountSettings accountSettings) {
    _connection = connection;
    _accountSettings = accountSettings;
    _connection.connectionStateStream.listen((state) => {
          if (state == XmppConnectionState.DoneServiceDiscovery)
            {_connection.setState(XmppConnectionState.Ready)}
        });
  }

  void init() {
    _initSupportedFeaturesList();
    waitingNegotiators.clear();
  }

  void negotiateFeatureList(xml.XmlElement element) {
    print("Negotating features");
    List<Nonza> nonzas = element.descendants
        .whereType<xml.XmlElement>()
        .map((element) => Nonza.parse(element))
        .toList();
    //supportedNegotiatorList.sort((a,b) => a.priorityLevel.compareTo(b.priorityLevel));
    supportedNegotiatorList.forEach((negotiator)  {
          nonzas.forEach((nonza) {
                if (negotiator.match(nonza))
                  {
                    waitingNegotiators.add(
                        Tuple2<ConnectionNegotiator, Nonza>(negotiator, nonza));
                  };
              });
        });
    //nonzas.sort((a, b) => findNonzaPriority(a).compareTo(findNonzaPriority(b)));
    //nonzas.forEach((feature) => _checkFeature(feature));
    negotiateNextFeature();
  }

  void _checkFeature(Nonza nonza) {
    supportedNegotiatorList.forEach((feature) {
      if (feature.match(nonza)) {
        waitingNegotiators
            .add(Tuple2<ConnectionNegotiator, Nonza>(feature, nonza));
      }
    });
  }

  void cleanNegotiators() {
    waitingNegotiators.clear();
    if (activeFeature != null) {
      activeFeature.backToIdle();
      activeFeature = null;
    }
    if (activeSubscription != null) {
      activeSubscription.cancel();
    }
  }

  void negotiateNextFeature() {
    var tuple = pickNextNegotiator();
    if (tuple != null) {
      activeFeature = tuple.item1;
      activeFeature.negotiate(tuple.item2);
      //TODO: this should be refactored
      if (activeSubscription != null) activeSubscription.cancel();
      if (activeFeature != null) print('ACTIVE FEATURE: ' + tuple.item2.buildXmlString());
      activeSubscription =
          activeFeature.featureStateStream.listen(stateListener);
    } else {
      activeFeature = null;
      _connection.doneParsingFeatures();
    }
  }

  void _initSupportedFeaturesList() {
    var streamManagement = StreamManagementModule.getInstance(_connection);
    supportedNegotiatorList.add(StartTlsNegotiator(_connection)); //priority 1
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
    supportedNegotiatorList.add(ServiceDiscoveryNegotiator(_connection));
  }

  void stateListener(NegotiatorState state) {
    if (state == NegotiatorState.NEGOTIATING) {
      print("Feature Started Parsing");
    } else if (state == NegotiatorState.DONE_CLEAN_OTHERS) {
      cleanNegotiators();
    } else if (state == NegotiatorState.DONE) {
      negotiateNextFeature();
    }
  }

  int findNonzaPriority(Nonza nonza) {
    var feature = supportedNegotiatorList
        .firstWhere((feature) => feature.match(nonza), orElse: () => null);
    if (feature == null) {
      return ConnectionNegotiator.defaultPriorityLevel;
    } else {
      return feature.priorityLevel;
    }
  }

  Tuple2<ConnectionNegotiator, Nonza> pickNextNegotiator() {
    if (waitingNegotiators.isEmpty) return null;
    waitingNegotiators.forEach((it) => it.toString());
    var element = waitingNegotiators.firstWhere((element) {
      print('ELEMENT ' + element.item1.isReady().toString());
      return element.item1.isReady();
    }, orElse: ()  {
      print('No elements');
      waitingNegotiators.forEach((it) => it.toString());
    });
    waitingNegotiators.remove(element);
    return element;
  }
}
