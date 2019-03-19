import 'dart:collection';

import 'package:xmpp/src/elements/nonzas/Nonza.dart';
import 'package:xmpp/src/features/BindingResourceFeature.dart';
import 'package:xmpp/src/features/Feature.dart';
import 'package:xmpp/src/features/SessionInitiationFeature.dart';
import 'package:xmpp/src/features/StartTlsFeature.dart';
import 'package:xmpp/src/features/sasl/SaslLAuthenticationFeature.dart';
import 'package:xmpp/xmpp.dart';
import 'package:xml/xml.dart' as xml;
import 'package:tuple/tuple.dart';

class StreamFeaturesManager {


  List<Feature> supportedFeaturesList = List<Feature>();
  Feature activeFeature;
  Queue<Tuple2<Feature, Nonza>> waitingFeatures = Queue<Tuple2<Feature, Nonza>>();

  Connection _connection;

  String _password;

  StreamFeaturesManager(Connection connection, String password){
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
    supportedFeaturesList.forEach((feature) {
      if (feature.match(nonza)) {
        waitingFeatures.add(new Tuple2<Feature, Nonza>(feature, nonza));
      }
    });
  }

  void negotiateNextFeature() {
    if (waitingFeatures.isNotEmpty) {
      Tuple2<Feature, Nonza> tuple = waitingFeatures.removeFirst();
      activeFeature = tuple.item1;
      activeFeature.negotiate(tuple.item2);
      activeFeature.featureStateStream.listen(stateListener);
    } else {
      activeFeature = null;
      _connection.doneParsingFeatures();
    }
  }


 void _initSupportedFeaturesList() {
    supportedFeaturesList.add(new StartTlsFeature(_connection));
    supportedFeaturesList.add(new SaslAuthenticationFeature(_connection, _password));
    supportedFeaturesList.add(new BindingResourceFeature(_connection));
    supportedFeaturesList.add(new SessionInitiationFeature(_connection));
 }
 
 void stateListener(FeatureState state) {
   if (state == FeatureState.PARSING) {
     print("Feature Started Parsing");
   } else if (state == FeatureState.DONE) {
     negotiateNextFeature();
   }
 }


}