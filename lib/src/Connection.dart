import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:synchronized/synchronized.dart';

import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/nonzas/Nonza.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/features/ConnectionNegotatiorManager.dart';
import 'package:xmppstone/src/parser/StanzaParser.dart';
import 'package:xmppstone/src/presence/PresenceManager.dart';
import 'package:xmppstone/src/roster/RosterManager.dart';
import 'package:xmppstone/xmppstone.dart';

enum XmppConnectionState {
  Closed,
  ReceivingFeatures,
  DoneParsingFeatures,
  StartTlsFailed,
  AuthenticationNotSuppored,
  PlainAuthentication,
  Authenticating,
  Authenticated,
  AuthenticationFailure,
  SessionInitialized,
  DoneServiceDiscovery
}

class Connection {
  var lock = new Lock(reentrant: true);

  static Map<String, Connection> instances = Map<String, Connection>();

  static getInstance(String fullJid, String password, int port) {
    Connection connection = instances[fullJid];
    if (connection == null) {
      connection = Connection(fullJid, password, port);
      instances[fullJid] = connection;
    }
    return connection;
  }

  int _port;
  String _streamId;
  String _password;
  Jid _fullJid;

  bool authenticated = false;

  StreamController<AbstractStanza> _stanzaStreamController =
      new StreamController.broadcast();
  StreamController<Nonza> _nonzaStreamController =
      new StreamController.broadcast();

  StreamController<XmppConnectionState> _connectionStateStreamController =
      new StreamController.broadcast();

  Stream<AbstractStanza> get stanzasStream {
    return _stanzaStreamController.stream;
  }

  Stream<Nonza> get nonzasStream {
    return _nonzaStreamController.stream;
  }

  Stream<XmppConnectionState> get connectionStateStream {
    return _connectionStateStreamController.stream;
  }

  bool _logXML = true;

  Jid get fullJid => _fullJid;

  ConnectionNegotatiorManager streamFeaturesManager;

  @override
  void fullJidRetrieved(Jid jid) {
    fullJid = jid;
  }

  set fullJid(Jid value) {
    _fullJid = value;
  }

  Socket _socket;

  // for testing purpose
  set socket(Socket value) {
    _socket = value;
  }

  XmppConnectionState _state = XmppConnectionState.Closed;

  Connection(String jid, String password, int port) {
    _fullJid = Jid.fromFullJid(jid);
    _password = password;
    _port = port;
    streamFeaturesManager = new ConnectionNegotatiorManager(this, password);
    RosterManager.getInstance(this);
    PresenceManager.getInstance(this);
    MessageHandler.getInstance(this);
  }

  void _openStream() {
    String streamOpeningString = """
      <stream:stream
  from='${_fullJid.userAtDomain}'
  to='${_fullJid.domain}'
  version='1.0'
  xml:lang='en'
  xmlns='jabber:client'
  xmlns:stream='http://etherx.jabber.org/streams'>""";
    write(streamOpeningString);
  }

  String prepareStreamResponse(String response) {
    if (response.contains("stream:stream") &&
        !(response.contains("</stream>"))) {
      response = response + "</stream>"; // fix for crashing xml library
    }
    if (_logXML) {
      print("response: ${response}");
    }
    if (response.contains("</stream:stream>")) {
      close();
      return "";
    }
    return response;
  }

  void open() {
    if (_state == XmppConnectionState.Closed) {
      Socket.connect(_fullJid.domain, _port).then((Socket socket) {
        _socket = socket;
        socket
            .transform(utf8.decoder)
            .map(prepareStreamResponse)
            .listen(handleResponse);
        _openStream();
        setState(XmppConnectionState.ReceivingFeatures);
      });
    }
  }

  void close() {
    _socket.write('</stream:stream>');
    setState(XmppConnectionState.Closed);
  }

  bool stanzaMatcher(xml.XmlElement element) {
    String name = element.name.local;
    return name == "iq" || name == "message" || name == "presence";
  }

  bool nonzaMatcher(xml.XmlElement element) {
    String name = element.name.local;
    return name != "iq" && name != "message" && name != "presence";
  }

  bool featureMatcher(xml.XmlElement element) {
    String name = element.name.local;
    return (name == "stream:features" || name == "features");
  }

  void handleResponse(String response) {
    if (response != null && response.isNotEmpty) {
      var xmlResponse = xml.parse(response);
      if (xmlResponse.findElements("stream:stream").isNotEmpty) {
        processInitialStream(xmlResponse);
      }

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => stanzaMatcher(element))
          .map((xmlElement) => StanzaParser.parseStanza(xmlElement))
          .forEach((stanza) => _stanzaStreamController.add(stanza));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => featureMatcher(element))
          .forEach(
              (feature) => streamFeaturesManager.negotiateFeatureList(feature));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => nonzaMatcher(element))
          .map((xmlElement) => Nonza.parse(xmlElement))
          .forEach((nonza) => _nonzaStreamController.add(nonza));

      if (xmlResponse.findAllElements("stream:error").isNotEmpty) {
        processError(xmlResponse);
      }
    }
  }

  void processInitialStream(xml.XmlDocument xmlResponse) {
    print("processInitialStream");
    xmlResponse
        .findElements("stream:stream")
        .forEach((element) => _streamId = element.getAttribute("id"));
  }

  void write(message) {
    if (_logXML) {
      print("sending: " + message);
    }
    _socket.write(message);
  }

  void writeStanza(AbstractStanza stanza) {
    write(stanza.buildXmlString());
  }

  void writeNonza(Nonza nonza) {
    write(nonza.buildXmlString());
  }

  void setState(XmppConnectionState state) {
    _state = state;
    _fireConnectionStateChangedEvent(state);
    _processState(state);
    print("State: ${_state}");
  }

  XmppConnectionState get state {
    return _state;
  }

  void _processState(XmppConnectionState state) {
    if (state == XmppConnectionState.Authenticated) {
      authenticated = true;
      _openStream();
    }
  }

  void processError(xml.XmlDocument xmlResponse) {
    //todo find error stanzas
  }

  void startSecureSocket() {
    print(startSecureSocket);
    SecureSocket.secure(_socket).then((secureSocket) {
      _socket = secureSocket;
      _socket
          .transform(utf8.decoder)
          .map(prepareStreamResponse)
          .listen(handleResponse);
      _openStream();
    });
  }

  void fireNewStanzaEvent(AbstractStanza stanza) {
    _stanzaStreamController.add(stanza);
  }

  void _fireConnectionStateChangedEvent(XmppConnectionState state) {
    _connectionStateStreamController.add(state);
  }

  bool elementHasAttribute(xml.XmlElement element, xml.XmlAttribute attribute) {
    var list = element.attributes.firstWhere(
        (attr) =>
            attr.name.local == attribute.name.local &&
            attr.value == attribute.value,
        orElse: () => null);
    return list != null;
  }

  @override
  void sessionReady() {
    setState(XmppConnectionState.SessionInitialized);
    //now we should send presence
  }

  void doneParsingFeatures() {
    print("DONE PARSING FATURES");
    setState(XmppConnectionState.DoneParsingFeatures);
  }

  void startTlsFailed() {
    setState(XmppConnectionState.StartTlsFailed);
    close();
  }


  void authenticating() {
    setState(XmppConnectionState.Authenticating);
  }
}
