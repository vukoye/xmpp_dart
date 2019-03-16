import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cryptoutils/utils.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp/src/SessionRequestManager.dart';
import 'package:synchronized/synchronized.dart';

import 'package:xmpp/src/BindingResourceManager.dart';
import 'package:xmpp/src/ConnectionStateChangedListener.dart';
import 'package:xmpp/src/StanzaListener.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/parser/StanzaParser.dart';
import 'package:xmpp/src/roster/RosterManager.dart';
import 'package:xmpp/xmpp.dart';

enum XmppConnectionState {
  Closed,
  ReceivingFeatures,
  PLaidAuthentication,
  Authentication,
  StartTlsSent,
  StartingTls,
  Authenticated,
  InitialStreamUponAuthentication,
  AuthenticationFailure,
  BindingResources,
  SessionInitiation,
  SessionInitialized
}

class Connection
    implements BindingResourceCallBack, SessionRequestManagerCallback {
  String streamOpeningString = """
      <stream:stream
      from='user@domain'
  to='xmpp.jp'
  version='1.0'
  xml:lang='en'
  xmlns='jabber:client'
  xmlns:stream='http://etherx.jabber.org/streams'>""";

  var lock = new Lock(reentrant: true);

  String startTls = """<starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>""";

  int _port;
  String _streamId;
  String _password;
  Jid _fullJid;
  bool waitingForSessionInitiation = false;

  List<StanzaProcessor> stanzaListeners = new List<StanzaProcessor>();
  List<ConnectionStateChangedListener> connectionStateListeners =
      new List<ConnectionStateChangedListener>();

  Jid get fullJid => _fullJid;

  BindingResourceManager bindingResourceManager;
  SessionRequestManager sessionRequestManager;
  RosterManager rosterManager;

  @override
  void fullJidRetrieved(Jid jid) {
    fullJid = jid;
    if (_state == XmppConnectionState.BindingResources &&
        waitingForSessionInitiation) {
      _state = XmppConnectionState.SessionInitiation;
      waitingForSessionInitiation = false;
      initiateSession();
    }
  }

  set fullJid(Jid value) {
    _fullJid = value;
  }

  Socket _socket = null;
  Completer _completer;
  XmppConnectionState _state = XmppConnectionState.Closed;

  //IqStanzaHandler iqStanzaHandler;

  Connection(String jid, String password, int port) {
    _fullJid = Jid.fromFullJid(jid);
    _password = password;
    _port = port;
    //iqStanzaHandler = new IqStanzaHandler(this);
    bindingResourceManager = new BindingResourceManager(this);
    addStanzaListener(bindingResourceManager);
    sessionRequestManager = new SessionRequestManager(this);
    addStanzaListener(sessionRequestManager);
    rosterManager = RosterManager.getInstance(this);
    MessageHandler.getInstance(this);
  }

  Future open() {
    _completer = new Completer();
    Socket.connect(_fullJid.domain, _port).then((Socket socket) {
      _socket = socket;
      socket.transform(utf8.decoder).listen(handleResponse);
      write(streamOpeningString);
      setState(XmppConnectionState.ReceivingFeatures);
    });
    return _completer.future;
  }

  void close() {
    _socket.write('</stream:stream>');
    setState(XmppConnectionState.Closed);
    _completer.complete();
  }

  void handleResponse(String response) {
      bool closeConnection = false;
      if (response.contains("stream:stream") &&
          !(response.contains("</stream>"))) {
        response = response + "</stream>"; // fix for crashing xml library
      }
      if (response.contains("</stream:stream>")) {
        closeConnection = true;
        var index = response.lastIndexOf("</stream:stream>");
        response = response.substring(0, index);
      }
      print('handleResponse');
      print(response);
      if (response.isNotEmpty) {
        var xmlResponse = xml.parse(response);
        if (xmlResponse
            .findElements("stream:stream")
            .isNotEmpty) {
          processInitialStream(xmlResponse);
        }
        xmlResponse.findElements('iq').forEach((element) {
          var stanza = StanzaParser.parseStanza(element);
          fireNewStanzaEvent(stanza);
        });
        if (xmlResponse
            .findAllElements("stream:features")
            .isNotEmpty) {
          processFeatures(xmlResponse);
        }
        if (xmlResponse
            .findAllElements("stream:error")
            .isNotEmpty) {
          processError(xmlResponse);
        }
        xmlResponse.findAllElements("proceed").forEach((element) {
          if (_state == XmppConnectionState.StartTlsSent &&
              element.attributes.firstWhere((attribute) =>
              attribute.name.local == "xmlns" &&
                  attribute.value == "urn:ietf:params:xml:ns:xmpp-tls") !=
                  null) {
            setState(XmppConnectionState.StartingTls);
            startSecureSocket();
          }
        });
        if (_state == XmppConnectionState.PLaidAuthentication) {
          proccesAuthResponse(xmlResponse);
        }
        if (_state == XmppConnectionState.Authenticated) {
          write(streamOpeningString);
        }
      }
      if (closeConnection) {
        print("closing Connection");
        close();
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

  void processFeatures(xml.XmlDocument xmlResponse) {
    print("processing features");
    xmlResponse.findAllElements("mechanisms").forEach((element) {
      var mech = element.findElements("mechanism").toList();
      if (mech.first.toString().contains("PLAIN")) {
        setState(XmppConnectionState.PLaidAuthentication);
        sendPlainAuthMessage();
      }
    });
    if (xmlResponse.findAllElements("starttls").isNotEmpty) {
      write(startTls);
      setState(XmppConnectionState.StartTlsSent);
    }

    if (xmlResponse.findAllElements("bind").isNotEmpty) {
      setState(XmppConnectionState.BindingResources);
      write(bindingResourceManager.getBindRequestStanza().buildXmlString());
    }

    if (xmlResponse.findAllElements("session").isNotEmpty) {
      if (_state == XmppConnectionState.BindingResources) {
        waitingForSessionInitiation = true;
      }
    }
  }

  void sendPlainAuthMessage() {
    var authString = '\u0000' + _fullJid.local + '\u0000' + _password;
    var bytes = utf8.encode(authString);
    var base64 = CryptoUtils.bytesToBase64(bytes);
    String message =
        "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>${base64}</auth>";
    write(message);
  }

  void write(message) {
    print("sending: " + message);
    _socket.write(message);
  }

  void writeStanza(AbstractStanza stanza) {
    write(stanza.buildXmlString());
  }

  void setState(XmppConnectionState state) {
    _state = state;
    _fireConnectionStateChangedEvent(state);
    print("State: ${_state}");
  }

  void processError(xml.XmlDocument xmlResponse) {
    //todo find error stanzas
  }

  void startSecureSocket() {
    //todo do we need to close oldSocket?
    print(startSecureSocket);
    SecureSocket.secure(_socket).then((secureSocket) {
      _socket = secureSocket;
      _socket.transform(utf8.decoder).listen(handleResponse);
      write(streamOpeningString);
    });
  }

  void proccesAuthResponse(xml.XmlDocument xmlResponse) {
    xmlResponse.findAllElements("success").forEach((element) {
      if (elementHasAttribute(
          element,
          xml.XmlAttribute(
              xml.XmlName("xmlns"), "urn:ietf:params:xml:ns:xmpp-sasl"))) {
        setState(XmppConnectionState.Authenticated);
        return;
      }
    });
    xmlResponse.findAllElements("failure").forEach((element) {
      if (elementHasAttribute(
          element,
          xml.XmlAttribute(
              xml.XmlName("xmlns"), "urn:ietf:params:xml:ns:xmpp-sasl"))) {
        setState(XmppConnectionState.AuthenticationFailure);
        return;
      }
    });
  }

  void fireNewStanzaEvent(AbstractStanza stanza) {
      print("FireNewStanza");
      stanzaListeners.forEach((listener) => listener.processStanza(stanza));
  }

  void addStanzaListener(StanzaProcessor listener) {
      print("addStanzaListener");
      stanzaListeners.add(listener);
  }

  void removeStanzaListener(StanzaProcessor listener) {
    stanzaListeners.remove(listener);
  }

  void _fireConnectionStateChangedEvent(XmppConnectionState state) {
    connectionStateListeners
        .forEach((listener) => listener.onConnectionStateChanged(state));
  }

  void addConnectionStateChangedListener(
      ConnectionStateChangedListener listener) {
    connectionStateListeners.add(listener);
  }

  void removeConnectionStateChangedListener(
      ConnectionStateChangedListener listener) {
    connectionStateListeners.remove(listener);
  }

  bool elementHasAttribute(xml.XmlElement element, xml.XmlAttribute attribute) {
    var list = element.attributes.firstWhere(
        (attr) =>
            attr.name.local == attribute.name.local &&
            attr.value == attribute.value,
        orElse: () => null);
    return list != null;
  }

  //should work with connection state changed
  void initiateSession() {
    write(sessionRequestManager
        .getSessionRequestStanza(fullJid.domain)
        .buildXmlString());
  }

  @override
  void sessionReady() {
    setState(XmppConnectionState.SessionInitialized);
    //now we should send presence
  }
}
