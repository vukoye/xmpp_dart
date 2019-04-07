import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:synchronized/synchronized.dart';
import 'package:xmpp_stone/src/account/XmppAccount.dart';

import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/presence/PresenceManager.dart';
import 'package:xmpp_stone/src/roster/RosterManager.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

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

  XmppAccount _account;

  static getInstance(XmppAccount account) {
    Connection connection = instances[account.fullJid.fullJid];
    if (connection == null) {
      connection = Connection(account);
      instances[account.fullJid.fullJid] = connection;
    }
    return connection;
  }

  String _streamId;
  String _errorMessage;

  String get errorMessage => _errorMessage;

  set errorMessage(String value) {
    _errorMessage = value;
  }

  bool authenticated = false;

  StreamController<AbstractStanza> _inStanzaStreamController =
      new StreamController.broadcast();

  StreamController<Nonza> _nonzaStreamController =
      new StreamController.broadcast();

  StreamController<XmppConnectionState> _connectionStateStreamController =
      new StreamController.broadcast();

  Stream<AbstractStanza> get inStanzasStream {
    return _inStanzaStreamController.stream;
  }

  Stream<Nonza> get nonzasStream {
    return _nonzaStreamController.stream;
  }

  Stream<XmppConnectionState> get connectionStateStream {
    return _connectionStateStreamController.stream;
  }

  bool _logXML = true;

  Jid get fullJid => _account.fullJid;

  ConnectionNegotatiorManager streamFeaturesManager;

  @override
  void fullJidRetrieved(Jid jid) {
    _account.resource = jid.resource;
  }


  Socket _socket;

  // for testing purpose
  set socket(Socket value) {
    _socket = value;
  }

  XmppConnectionState _state = XmppConnectionState.Closed;

  Connection(this._account) {
    streamFeaturesManager = new ConnectionNegotatiorManager(this, _account.password);
    RosterManager.getInstance(this);
    PresenceManager.getInstance(this);
    MessageHandler.getInstance(this);
  }

  void _openStream() {
    String streamOpeningString = """
      <stream:stream
  from='${_account.fullJid.userAtDomain}'
  to='${fullJid.domain}'
  version='1.0'
  xml:lang='en'
  xmlns='jabber:client'
  xmlns:stream='http://etherx.jabber.org/streams'>""";
    write(streamOpeningString);
  }

  String prepareStreamResponse(String response) {
    if (response.contains("stream:stream") &&
        !(response.contains("</stream>"))) {
      response = response + "</stream>"; // fix for crashing xml library without ending
    }

    //fix for multiple roots issue
    response = "<xmpp_stone>$response</xmpp_stone>";

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
      Socket.connect(_account.domain, _account.port).then((Socket socket) {
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
    setState(XmppConnectionState.Closed);
    _socket.write('</stream:stream>');
    _socket.close();
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

  String _unparsedXmlResponse = "";

  void handleResponse(String response) {

    String fullResponse;
    if (_unparsedXmlResponse.isNotEmpty) {
      fullResponse = _unparsedXmlResponse + response.substring(11);  // remove xmpp_stone start tag
      _unparsedXmlResponse = "";
    } else {
      fullResponse = response;
    }

    if (fullResponse != null && fullResponse.isNotEmpty) {
      var xmlResponse;
      try {
         xmlResponse = xml
            .parse(fullResponse)
            .firstChild;
      } catch (e) {
        _unparsedXmlResponse += response.substring(0, response.length - 12); //remove  xmpp_stone end tag
        xmlResponse = xml.XmlElement(xml.XmlName("error"));
      }

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => element.name == "stream:stream")
          .forEach((element) => processInitialStream(element));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => stanzaMatcher(element))
          .map((xmlElement) => StanzaParser.parseStanza(xmlElement))
          .forEach((stanza) => _inStanzaStreamController.add(stanza));

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

//      if (xmlResponse.findAllElements("stream:error").isNotEmpty) {
//        processError(xmlResponse);
//      }
    }
  }

  void processInitialStream(xml.XmlElement initialStream) {
    print("processInitialStream");
    var value = initialStream.getAttribute("id");
    if (value != null) {
      _streamId = value;
    }
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
    _inStanzaStreamController.add(stanza);
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
