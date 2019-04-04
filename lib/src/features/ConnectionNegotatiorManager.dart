import 'dart:collection';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/BindingResourceNegotiator.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'package:xmpp_stone/src/features/SessionInitiationNegotiator.dart';
import 'package:xmpp_stone/src/features/StartTlsNegotatior.dart';
import 'package:xmpp_stone/src/features/sasl/SaslAuthenticationFeature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoveryNegotiator.dart';
import 'package:xml/xml.dart' as xml;
import 'package:tuple/tuple.dart';

class ConnectionNegotatiorManager {


  List<ConnectionNegotiator> supportedNegotatiorList = List<ConnectionNegotiator>();
  ConnectionNegotiator activeFeature;
  Queue<Tuple2<ConnectionNegotiator, Nonza>> waitingNegotators = Queue<Tuple2<ConnectionNegotiator, Nonza>>();

  Connection _connection;

  String _password;

  ConnectionNegotatiorManager(Connection connection, String password){
    _password = password;
    _connection = connection;
    _initSupportedFeaturesList();
  }

  void negotiateFeatureList(xml.XmlElement element) {
    print("Negotating features");
    element.descendants.whereType<xml.XmlElement>().map((element) => Nonza.parse(element))
        .forEach((feature) => _checkFeature(feature));
    negotiateNextFeature();
  }

  void _checkFeature(Nonza nonza) {
    supportedNegotatiorList.forEach((feature) {
      if (feature.match(nonza)) {
        waitingNegotators.add(new Tuple2<ConnectionNegotiator, Nonza>(feature, nonza));
      }
    });
  }

  void negotiateNextFeature() {
    if (waitingNegotators.isNotEmpty) {
      Tuple2<ConnectionNegotiator, Nonza> tuple = waitingNegotators.removeFirst();
      activeFeature = tuple.item1;
      activeFeature.negotiate(tuple.item2);
      activeFeature.featureStateStream.listen(stateListener);
    } else {
      activeFeature = null;
      _connection.doneParsingFeatures();
    }
  }


 void _initSupportedFeaturesList() {
    supportedNegotatiorList.add(new StartTlsNegotiator(_connection));
    supportedNegotatiorList.add(new SaslAuthenticationFeature(_connection, _password));
    supportedNegotatiorList.add(new BindingResourceConnectionNegotiator(_connection));
    supportedNegotatiorList.add(new SessionInitiationNegotiator(_connection));
    supportedNegotatiorList.add(new ServiceDiscoveryNegotiator(_connection));
 }
 
 void stateListener(NegotiatorState state) {
   if (state == NegotiatorState.NEGOTIATING) {
     print("Feature Started Parsing");
   } else if (state == NegotiatorState.DONE) {
     negotiateNextFeature();
   }
 }


}