import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptoutils/utils.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp/src/SessionRequestManager.dart';
import 'package:synchronized/synchronized.dart';

import 'package:xmpp/src/BindingResourceManager.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/nonzas/Nonza.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/features/StreamFeaturesManager.dart';
import 'package:xmpp/src/parser/StanzaParser.dart';
import 'package:xmpp/src/presence/PresenceManager.dart';
import 'package:xmpp/src/roster/RosterManager.dart';
import 'package:xmpp/xmpp.dart';

enum XmppConnectionState {
  Closed,
  ReceivingFeatures,
  StartTlsFailed,
  AuthenticationNotSuppored,
  PlainAuthentication,
  Authenticating,
  Authenticated,
  InitialStreamUponAuthentication,
  AuthenticationFailure,
  BindingResources,
  SessionInitiation,
  SessionInitialized
}

class Connection
    implements BindingResourceCallBack, SessionRequestManagerCallback {
  var lock = new Lock(reentrant: true);

  String startTls = """<starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>""";

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

  //BindingResourceManager bindingResourceManager;
  StreamFeaturesManager streamFeaturesManager;
  RosterManager _rosterManager;
  PresenceManager _presenceManager;

  @override
  void fullJidRetrieved(Jid jid) {
    fullJid = jid;
//    if (_state == XmppConnectionState.BindingResources &&
//        waitingForSessionInitiation) {
//      _state = XmppConnectionState.SessionInitiation;
//      waitingForSessionInitiation = false;
      //initiateSession();
 //   }
  }

  set fullJid(Jid value) {
    _fullJid = value;
  }

  Socket _socket = null;
  Completer _completer;
  XmppConnectionState _state = XmppConnectionState.Closed;

  Connection(String jid, String password, int port) {
    _fullJid = Jid.fromFullJid(jid);
    _password = password;
    _port = port;

//    bindingResourceManager = new BindingResourceManager(this);
//    stanzasStream.listen(bindingResourceManager.processStanza);
    streamFeaturesManager = new StreamFeaturesManager(this, password);
    _rosterManager = RosterManager.getInstance(this);
    _presenceManager = PresenceManager.getInstance(this);
    MessageHandler.getInstance(this);
  }

  void openStream() {
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

  Future open() {
    _completer = new Completer();
    Socket.connect(_fullJid.domain, _port).then((Socket socket) {
      _socket = socket;
      socket
          .transform(utf8.decoder)
          .map(prepareStreamResponse)
          .listen(handleResponse);
      openStream();
      setState(XmppConnectionState.ReceivingFeatures);
    });
    return _completer.future;
  }

  void close() {
    _socket.write('</stream:stream>');
    setState(XmppConnectionState.Closed);
    _completer.complete();
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
    if (_state == XmppConnectionState.Authenticated) {
      setState(XmppConnectionState.InitialStreamUponAuthentication);
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

  void _processState(XmppConnectionState state) {
    if (state == XmppConnectionState.Authenticated) {
      authenticated = true;
      openStream();
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
      openStream();
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

  }

  void startTlsFailed() {
    setState(XmppConnectionState.StartTlsFailed);
    close();
  }


  void authenticating() {
    setState(XmppConnectionState.Authenticating);
  }
}
