import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Feature.dart';
import 'package:xmpp_stone/src/features/servicediscovery/Identity.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoverySupport.dart';

class ServiceDiscoveryNegotiator extends ConnectionNegotiator {
  static const String NAMESPACE_DISCO_INFO =
      "http://jabber.org/protocol/disco#info";

  static Map<Connection, ServiceDiscoveryNegotiator> _instances =
      Map<Connection, ServiceDiscoveryNegotiator>();

  static ServiceDiscoveryNegotiator getInstance(Connection connection) {
    ServiceDiscoveryNegotiator instance = _instances[connection];
    if (instance == null) {
      instance = ServiceDiscoveryNegotiator(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  IqStanza fullRequestStanza;

  StreamSubscription<AbstractStanza> subscription;

  Connection _connection;

  ServiceDiscoveryNegotiator(this._connection) {
    _connection.connectionStateStream.listen((state) {
      if (state == XmppConnectionState.SessionInitialized) {
        negotiate(null);
      }
    });
  }

  StreamController<XmppElement> _errorStreamController =
      StreamController<XmppElement>();

  List<Feature> _supportedFeatures = List<Feature>();

  List<Identity> _supportedIdentities = List<Identity>();

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
  bool match(Nonza request) {
    return _connection.state == XmppConnectionState.SessionInitialized;
  }

  @override
  void negotiate(Nonza nonza) {
    if (state == NegotiatorState.IDLE) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(_parseStanza);
      _sendServiceDiscoveryRequest();
    } else if (state == NegotiatorState.DONE){
      _connection.setState(XmppConnectionState.DoneServiceDiscovery);
    }
  }

  void _sendServiceDiscoveryRequest() {
    IqStanza request = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    request.fromJid = _connection.fullJid;
    request.toJid = _connection.serverName;
    XmppElement queryElement = XmppElement();
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
      XmppElement queryStanza = stanza.getChild('query');
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
      XmppElement errorStanza = stanza.getChild('error');
      if (errorStanza != null) {
        _errorStreamController.add(errorStanza);
      }
    }
    state = NegotiatorState.DONE;
    subscription.cancel();
    _connection.setState(XmppConnectionState.DoneServiceDiscovery);

  }

  bool isFeatureSupported(String feature) {
    return _supportedFeatures.firstWhere(
            (element) => element.textValue == feature,
            orElse: () => null) !=
        null;
  }

  bool isDiscoInfoQuery(IqStanza stanza) {
    return stanza.type == IqStanzaType.GET &&
        stanza.toJid.fullJid == _connection.fullJid.fullJid &&
        stanza.children
            .where((element) =>
                element.name == "query" &&
                element.getAttribute("xmlns")?.value == NAMESPACE_DISCO_INFO)
            .isNotEmpty;
  }

  void sendDiscoInfoResponse(IqStanza request) {
    IqStanza iqStanza = IqStanza(request.id, IqStanzaType.RESULT);
    //iqStanza.fromJid = _connection.fullJid; //do not send for now
    iqStanza.toJid = request.fromJid;
    XmppElement query = XmppElement();
    query.addAttribute(XmppAttribute("xmlns", NAMESPACE_DISCO_INFO));
    SERVICE_DISCOVERY_SUPPORT_LIST.forEach((featureName) {
      XmppElement featureElement = XmppElement();
      featureElement.addAttribute(XmppAttribute("feature", featureName));
      query.addChild(featureElement);
    });
    iqStanza.addChild(query);
    _connection.writeStanza(iqStanza);
  }
}
