import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:synchronized/synchronized.dart';
import 'package:xmpp_stone/src/ReconnectionManager.dart';
import 'package:xmpp_stone/src/account/XmppAccountSettings.dart';

import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/presence/PresenceManager.dart';
import 'package:xmpp_stone/src/roster/RosterManager.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

enum XmppConnectionState {
  Idle,
  Closed,
  SocketOpening,
  DoneParsingFeatures,
  StartTlsFailed,
  AuthenticationNotSupported,
  PlainAuthentication,
  Authenticating,
  Authenticated,
  AuthenticationFailure,
  Resumed,
  SessionInitialized,
  DoneServiceDiscovery,
  Ready,
  ForcelyClosed,
  Reconnecting
}

class Connection {
  var lock = Lock(reentrant: true);

  static Map<String, Connection> instances = Map<String, Connection>();

  XmppAccountSettings account;

  StreamManagementModule streamManagementModule;

  Jid get serverName {
    if (_serverName != null) {
      return Jid.fromFullJid(_serverName);
    } else {
      return Jid.fromFullJid(fullJid.domain); //todo move to account.domain!
    }
  } //move this somewhere

  String _serverName;

  static getInstance(XmppAccountSettings account) {
    Connection connection = instances[account.fullJid.userAtDomain];
    if (connection == null) {
      connection = Connection(account);
      instances[account.fullJid.userAtDomain] = connection;
    }
    return connection;
  }

  String _errorMessage;

  String get errorMessage => _errorMessage;

  set errorMessage(String value) {
    _errorMessage = value;
  }

  bool authenticated = false;

  StreamController<AbstractStanza> _inStanzaStreamController =
      StreamController.broadcast();

  StreamController<AbstractStanza> _outStanzaStreamController =
      StreamController.broadcast();

  StreamController<Nonza> _inNonzaStreamController =
      StreamController.broadcast();

  StreamController<Nonza> _outNonzaStreamController =
      StreamController.broadcast();

  StreamController<XmppConnectionState> _connectionStateStreamController =
      StreamController.broadcast();

  Stream<AbstractStanza> get inStanzasStream {
    return _inStanzaStreamController.stream;
  }

  Stream<Nonza> get inNonzasStream {
    return _inNonzaStreamController.stream;
  }

  Stream<Nonza> get outNonzasStream {
    return _inNonzaStreamController.stream;
  }

  Stream<AbstractStanza> get outStanzasStream {
    return _outStanzaStreamController.stream;
  }

  Stream<XmppConnectionState> get connectionStateStream {
    return _connectionStateStreamController.stream;
  }

  bool _logXML = true;

  Jid get fullJid => account.fullJid;

  ConnectionNegotatiorManager connectionNegotatiorManager;

  void fullJidRetrieved(Jid jid) {
    account.resource = jid.resource;
  }

  Socket _socket;

  // for testing purpose
  set socket(Socket value) {
    _socket = value;
  }

  XmppConnectionState _state = XmppConnectionState.Idle;

  ReconnectionManager reconnectionManager;

  Connection(this.account) {
    RosterManager.getInstance(this);
    PresenceManager.getInstance(this);
    MessageHandler.getInstance(this);
    reconnectionManager = ReconnectionManager(this);
  }

  void _openStream() {
    String streamOpeningString = """
<?xml version='1.0'?>
<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams'
to='${fullJid.domain}'
xml:lang='en'
>
""";

    write(streamOpeningString);
  }

  String restOfResponse = "";

  String extractWholeChild(String response) {
    return response;
  }

  String prepareStreamResponse(String response) {
    String response1 = extractWholeChild(restOfResponse + response);

    if (response1.contains("stream:stream") &&
        !(response1.contains("</stream>"))) {
      response1 = response1 +
          "</stream>"; // fix for crashing xml library without ending
    }

    //fix for multiple roots issue
    response1 = "<xmpp_stone>$response1</xmpp_stone>";

    if (_logXML) {
      print("response: ${response1}");
    }
    if (response1.contains("</stream:stream>")) {
      close();
      return "";
    }
    return response1;
  }

  void reconnect() {
    print("Reconnect!!!");
    if (_state == XmppConnectionState.ForcelyClosed) {
      setState(XmppConnectionState.Reconnecting);
      openSocket();
    }
  }

  void connect() {
    if (_state == XmppConnectionState.Closed) {
      _state == XmppConnectionState.Idle;
    }
    if (_state == XmppConnectionState.Idle) {
      openSocket();
    }
  }

  Future<void> openSocket() async {
    connectionNegotatiorManager =
        ConnectionNegotatiorManager(this, account.password);
    try {
      return await Socket.connect(account.domain, account.port).then((Socket socket) {
        _socket = socket;
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .map(prepareStreamResponse)
            .listen(handleResponse,
            onDone: handleConnectionDone);
        _openStream();
        setState(XmppConnectionState.SocketOpening);
      });
    } on SocketException catch(error) {
      print("Socket Exception" + error.toString());
      handleConnectionError(error.toString());
    }
  }

  void close() {
    if (state != XmppConnectionState.Closed) {
      if (state != XmppConnectionState.ForcelyClosed) {
        _socket.write('</stream:stream>');
        _socket.close();
      }
      setState(XmppConnectionState.Closed);
      authenticated = false;
    }
  }

  bool startMatcher(xml.XmlElement element) {
    String name = element.name.local;
    return name == "stream";
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
      print(_unparsedXmlResponse);
      fullResponse = "$_unparsedXmlResponse${response.substring(12)}"; //
      // remove xmpp_stone start tag
      print(_unparsedXmlResponse);
      _unparsedXmlResponse = "";
    } else {
      fullResponse = response;
    }

    if (fullResponse != null && fullResponse.isNotEmpty) {
      var xmlResponse;
      try {
        //print(fullResponse);
        xmlResponse = xml.parse(fullResponse).firstChild;
      } catch (e) {
        _unparsedXmlResponse += fullResponse.substring(
            0, fullResponse.length - 13); //remove  xmpp_stone end tag
        xmlResponse = xml.XmlElement(xml.XmlName("error"));
      }
//      xmlResponse.descendants.whereType<xml.XmlElement>().forEach((element) {
//        print("element: " + element.name.local);
//      });

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => startMatcher(element))
          .forEach((element) => processInitialStream(element));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => stanzaMatcher(element))
          .map((xmlElement) => StanzaParser.parseStanza(xmlElement))
          .forEach((stanza) => _inStanzaStreamController.add(stanza));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => featureMatcher(element))
          .forEach((feature) =>
              connectionNegotatiorManager.negotiateFeatureList(feature));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => nonzaMatcher(element))
          .map((xmlElement) => Nonza.parse(xmlElement))
          .forEach((nonza) => _inNonzaStreamController.add(nonza));

//      if (xmlResponse.findAllElements("stream:error").isNotEmpty) {
//        processError(xmlResponse);
//      }
    }
  }

  void processInitialStream(xml.XmlElement initialStream) {
    print("processInitialStream");
    String from = initialStream.getAttribute('from');
    if (from != null) {
      _serverName = from;
    }
  }

  bool isOpened() {
    return state != XmppConnectionState.Closed &&
        state != XmppConnectionState.ForcelyClosed;
  }

  void write(message) {
    if (_logXML) {
      print("sending: " + message);
    }
    if (isOpened()) {
      _socket.write(message);
    }
  }

  void writeStanza(AbstractStanza stanza) {
    _outStanzaStreamController.add(stanza);
    write(stanza.buildXmlString());
  }

  void writeNonza(Nonza nonza) {
    _outNonzaStreamController.add(nonza);
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
    print("startSecureSocket");
    print(state);
    SecureSocket.secure(_socket, onBadCertificate: _validateBadCertificate)
        .then((secureSocket) {
      _socket = secureSocket;
      _socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .map(prepareStreamResponse)
          .listen(handleResponse,
              onError: (error) => {handleSecuredConnectionError(error.toString())}, onDone: handleSecuredConnectionDone);
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

  bool _validateBadCertificate(X509Certificate certificate) {
    return true;
  }

  void handleConnectionDone() {
    print("!!!!!!!!!!!Handle connection done");
    if (state != XmppConnectionState.Closed) {
      setState(XmppConnectionState.ForcelyClosed);
    }
  }

  void handleSecuredConnectionDone() {
    print("!!!!!!!!!!!Handle secured connection done");
    if (state != XmppConnectionState.Closed) {
      setState(XmppConnectionState.ForcelyClosed);
    }
  }

  handleConnectionError(String error) {
    print("!!!!!!Handle ERROR " + error);
    if (state != XmppConnectionState.Closed) {
      setState(XmppConnectionState.ForcelyClosed);
    }
  }

  handleSecuredConnectionError(String error) {
    print("!!!!!!Handle Secured ERROR " + error);
    if (state != XmppConnectionState.Closed) {
      setState(XmppConnectionState.ForcelyClosed);
    }
  }
}
