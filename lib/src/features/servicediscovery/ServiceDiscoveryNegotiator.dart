

import 'dart:async';

import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/XmppAttribute.dart';
import 'package:xmppstone/src/elements/XmppElement.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/elements/stanzas/IqStanza.dart';
import 'package:xmppstone/src/features/Negotiator.dart';
import 'package:xmppstone/src/features/servicediscovery/Feature.dart';
import 'package:xmppstone/src/features/servicediscovery/Identity.dart';

class ServiceDiscoveryNegotiator extends ConnectionNegotiator{

  static Map<Connection, ServiceDiscoveryNegotiator> _instances = Map<Connection, ServiceDiscoveryNegotiator>();

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

  StreamController<XmppElement> _errorStreamController = StreamController<XmppElement>();

  List<Feature> _supportedFeatures = List<Feature>();

  List<Identity> _supportedIdentities = List<Identity>();

  Stream<XmppElement> get errorStream {
    return _errorStreamController.stream;
  }


  void _parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var idValue = stanza.getAttribute('id')?.value;
      if (idValue != null && idValue == fullRequestStanza?.getAttribute('id')?.value) {
        _parseFullInfoResponse(stanza);
      }
    }
  }

  @override
  bool match(Nonza request) {
    return _connection.state == XmppConnectionState.SessionInitialized;
  }

  @override
  void negotiate(Nonza nonza) {
    if (state != NegotiatorState.NEGOTIATING) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(_parseStanza);
      _sendServiceDiscoveryRequest();
    }
  }

  void _sendServiceDiscoveryRequest() {
    IqStanza request = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
    request.fromJid = _connection.fullJid;
    request.toJid = Jid.fromFullJid(_connection.fullJid.domain); //todo move to account.domain!
    XmppElement queryElement = XmppElement();
    queryElement.name = 'query';
    queryElement.addAttribute(XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));
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
    _connection.setState(XmppConnectionState.DoneServiceDiscovery);
  }

  bool isFeatureSupported(String feature) {
    return _supportedFeatures.firstWhere((element) => element.textValue == feature, orElse: () => null) != null;
  }
}