import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Feature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Identity.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoverySupport.dart';
import 'Feature.dart';

class ServiceDiscoveryNegotiator extends Negotiator {
  static const String NAMESPACE_DISCO_INFO =
      'http://jabber.org/protocol/disco#info';

  static final Map<Connection, ServiceDiscoveryNegotiator> _instances =
      <Connection, ServiceDiscoveryNegotiator>{};

  static ServiceDiscoveryNegotiator getInstance(Connection connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = ServiceDiscoveryNegotiator(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  IqStanza fullRequestStanza;

  StreamSubscription<AbstractStanza> subscription;

  final Connection _connection;

  ServiceDiscoveryNegotiator(this._connection) {
    _connection.connectionStateStream.listen((state) {
      expectedName = 'ServiceDiscoveryNegotiator';
    });
  }

  final StreamController<XmppElement> _errorStreamController =
      StreamController<XmppElement>();

  final List<Feature> _supportedFeatures = <Feature>[];

  final List<Identity> _supportedIdentities = <Identity>[];

  Stream<XmppElement> get errorStream {
    return _errorStreamController.stream;
  }

  void _parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null &&
          idValue == fullRequestStanza?.getAttribute('id')?.value) {
        _parseFullInfoResponse(stanza);
      } else if (isDiscoInfoQuery(stanza)) {
        sendDiscoInfoResponse(stanza);
      }
    }
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    return [];
  }

  @override
  void negotiate(List<Nonza> nonza) {
    if (state == NegotiatorState.IDLE) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(_parseStanza);
      _sendServiceDiscoveryRequest();
    } else if (state == NegotiatorState.DONE) {
    }
  }

  void _sendServiceDiscoveryRequest() {
    var request = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    request.fromJid = _connection.fullJid;
    request.toJid = _connection.serverName;
    var queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(
        XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));
    request.addChild(queryElement);
    fullRequestStanza = request;
    _connection.writeStanza(request);
  }

  void _parseFullInfoResponse(IqStanza stanza) {
    _supportedFeatures.clear();
    _supportedIdentities.clear();
    if (stanza.type == IqStanzaType.RESULT) {
      var queryStanza = stanza.getChild('query');
      if (queryStanza != null) {
        queryStanza.children.forEach((element) {
          if (element is Identity) {
            _supportedIdentities.add(element);
          } else if (element is Feature) {
            _supportedFeatures.add(element);
          }
        });
      }
    } else if (stanza.type == IqStanzaType.ERROR) {
      var errorStanza = stanza.getChild('error');
      if (errorStanza != null) {
        _errorStreamController.add(errorStanza);
      }
    }
    subscription.cancel();
    _connection.connectionNegotatiorManager.addFeatures(_supportedFeatures);
    state = NegotiatorState.DONE;
  }

  bool isFeatureSupported(String feature) {
    return _supportedFeatures.firstWhere(
            (element) => element.textValue == feature,
            orElse: () => null) !=
        null;
  }

  List<Feature> getSupportedFeatures() {
    return _supportedFeatures;
  }

  bool isDiscoInfoQuery(IqStanza stanza) {
    return stanza.type == IqStanzaType.GET &&
        stanza.toJid.fullJid == _connection.fullJid.fullJid &&
        stanza.children
            .where((element) =>
                element.name == 'query' &&
                element.getAttribute('xmlns')?.value == NAMESPACE_DISCO_INFO)
            .isNotEmpty;
  }

  void sendDiscoInfoResponse(IqStanza request) {
    var iqStanza = IqStanza(request.id, IqStanzaType.RESULT);
    //iqStanza.fromJid = _connection.fullJid; //do not send for now
    iqStanza.toJid = request.fromJid;
    var query = XmppElement();
    query.addAttribute(XmppAttribute('xmlns', NAMESPACE_DISCO_INFO));
    SERVICE_DISCOVERY_SUPPORT_LIST.forEach((featureName) {
      var featureElement = XmppElement();
      featureElement.addAttribute(XmppAttribute('feature', featureName));
      query.addChild(featureElement);
    });
    iqStanza.addChild(query);
    _connection.writeStanza(iqStanza);
  }
}

extension ServiceDiscoveryExtension on Connection {
  List<Feature> getSupportedFeatures() {
    return ServiceDiscoveryNegotiator.getInstance(this).getSupportedFeatures();
  }
}