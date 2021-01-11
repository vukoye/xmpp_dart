import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:synchronized/synchronized.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/ReconnectionManager.dart';
import 'package:xmpp_stone/src/account/XmppAccountSettings.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/StreamElement.dart';
import 'package:xmpp_stone/src/elements/StreamFeaturesElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/extensions/ping/PingManager.dart';
import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';
import 'package:xmpp_stone/src/parser/XmppParser.dart';
import 'package:xmpp_stone/src/presence/PresenceManager.dart';
import 'package:xmpp_stone/src/roster/RosterManager.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'logger/Log.dart';

enum XmppConnectionState {
  Idle,
  Closed,
  SocketOpening,
  SocketOpened,
  StartTlsFailed,
  AuthenticationNotSupported,
  Authenticating,
  Authenticated,
  AuthenticationFailure,
  Resumed,
  SessionInitialized,
  Ready,
  Closing,
  ForcefullyClosed,
  Reconnecting,
  WouldLikeToOpen,
}

class Connection {
  var lock = Lock(reentrant: true);

  static String TAG = 'Connection';

  bool useNewParser = true;

  static Map<String, Connection> instances = <String, Connection>{};

  XmppAccountSettings account;

  StreamManagementModule streamManagementModule;

  final XmppParser _xmppParser = XmppParser();

  void addCustomParser(XmppElementParser parser) {
    _xmppParser.addCustomParser(parser);
  }

  Jid get serverName {
    if (_serverName != null) {
      return Jid.fromFullJid(_serverName);
    } else {
      return Jid.fromFullJid(fullJid.domain); //todo move to account.domain!
    }
  } //move this somewhere

  String _serverName;

  static Connection getInstance(XmppAccountSettings account) {
    var connection = instances[account.fullJid.userAtDomain];
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

  final StreamController<AbstractStanza> _inStanzaStreamController =
      StreamController.broadcast();

  final StreamController<AbstractStanza> _outStanzaStreamController =
      StreamController.broadcast();

  final StreamController<XmppElement> _inNonzaStreamController =
      StreamController.broadcast();

  final StreamController<Nonza> _outNonzaStreamController =
      StreamController.broadcast();

  final StreamController<XmppConnectionState> _connectionStateStreamController =
      StreamController.broadcast();

  Stream<AbstractStanza> get inStanzasStream =>
      _inStanzaStreamController.stream;

  Stream<XmppElement> get inNonzasStream => _inNonzaStreamController.stream;

  Stream<Nonza> get outNonzasStream => _outNonzaStreamController.stream;

  Stream<AbstractStanza> get outStanzasStream => _outStanzaStreamController.stream;

  Stream<XmppConnectionState> get connectionStateStream => _connectionStateStreamController.stream;

  Jid get fullJid => account.fullJid;

  ConnectionNegotiatorManager connectionNegotiatorManager;

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
    PingManager.getInstance(this);
    connectionNegotiatorManager = ConnectionNegotiatorManager(this, account);
    reconnectionManager = ReconnectionManager(this);
  }

  void _openStream() {
    var streamOpeningString = """
<?xml version='1.0'?>
<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams'
to='${fullJid.domain}'
xml:lang='en'
>
""";
    write(streamOpeningString);
  }

  String restOfResponse = '';

  String prepareStreamResponse(String response) {
    Log.xmppp_receiving(response);
    var response1 = restOfResponse + response;
    if (response1.contains('</stream:stream>')) {
      close();
      return '';
    }
    if (response1.contains('stream:stream') &&
        !(response1.contains('</stream:stream>'))) {
      response1 = response1 +
          '</stream:stream>'; // fix for crashing xml library without ending
    }

    //fix for multiple roots issue
    response1 = '<xmpp_stone>$response1</xmpp_stone>';
    return response1;
  }

  void reconnect() {
    if (_state == XmppConnectionState.ForcefullyClosed) {
      setState(XmppConnectionState.Reconnecting);
      openSocket();
    }
  }

  void connect() {
    if (_state == XmppConnectionState.Closing) {
      _state = XmppConnectionState.WouldLikeToOpen;
    }
    if (_state == XmppConnectionState.Closed) {
      _state = XmppConnectionState.Idle;
    }
    if (_state == XmppConnectionState.Idle) {
      openSocket();
    }
  }

  Future<void> openSocket() async {
    connectionNegotiatorManager.init();
    setState(XmppConnectionState.SocketOpening);
    try {
      return await Socket.connect(account.host ?? account.domain, account.port)
          .then((Socket socket) {
        // if not closed in meantime
        if (_state != XmppConnectionState.Closed) {
          setState(XmppConnectionState.SocketOpened);
          _socket = socket;
          socket
              .cast<List<int>>()
              .transform(utf8.decoder)
              .map(prepareStreamResponse)
              .listen(handleResponse, onDone: handleConnectionDone);
          _openStream();
        } else {
          Log.d(TAG, 'Closed in meantime');
          socket.close();
        }
      });
    } on SocketException catch (error) {
      Log.e(TAG, 'Socket Exception' + error.toString());
      handleConnectionError(error.toString());
    }
  }

  void close() {
    if (state == XmppConnectionState.SocketOpening) {
      throw Exception('Closing is not possible during this state');
    }
    if (state != XmppConnectionState.Closed &&
        state != XmppConnectionState.ForcefullyClosed &&
        state != XmppConnectionState.Closing) {
      if (_socket != null) {
        try {
          setState(XmppConnectionState.Closing);
          _socket.write('</stream:stream>');
        } on Exception {
          Log.d(TAG, 'Socket already closed');
        }
      }
      authenticated = false;
    }
  }

  String _unparsedXmlResponse = '';

  void handleResponse(String response) {
    String fullResponse;
    if (_unparsedXmlResponse.isNotEmpty) {
      if (response.length > 12) {
        fullResponse = '$_unparsedXmlResponse${response.substring(12)}'; //
      } else {
        fullResponse = _unparsedXmlResponse;
      }
      Log.v(TAG, 'full response = ${fullResponse}');
      _unparsedXmlResponse = '';
    } else {
      fullResponse = response;
    }

    if (fullResponse != null && fullResponse.isNotEmpty) {
      xml.XmlNode xmlResponse;
      try {
        xmlResponse = xml.XmlDocument.parse(fullResponse).firstChild;
      } catch (e) {
        _unparsedXmlResponse += fullResponse.substring(
            0, fullResponse.length - 13); //remove  xmpp_stone end tag
        xmlResponse = xml.XmlElement(xml.XmlName('error'));
      }

      xmlResponse.children
          .whereType<xml.XmlElement>()
          .map((element) => _xmppParser.parse(element))
          .forEach((xmppElement) {
        if (xmppElement is StreamElement) {
          _serverName = xmppElement.serverName;
          xmppElement.children.forEach((element) {
            Log.d(TAG, 'Children ${element.name}');
          });
          var element = xmppElement.children.firstWhere(
              (element) => element is StreamFeaturesElement,
              orElse: () => null);
          if (element != null) {
            connectionNegotiatorManager.negotiateFeatureListXmpp(element);
          }
        }
        if (xmppElement is StreamFeaturesElement) {
          connectionNegotiatorManager.negotiateFeatureListXmpp(xmppElement);
        }
        if (xmppElement is AbstractStanza) {
          _inStanzaStreamController.add(xmppElement);
        } else {
          _inNonzaStreamController.add(xmppElement);
        }
      });
    }
  }

  void processInitialStream(xml.XmlElement initialStream) {
    Log.d(TAG, 'processInitialStream');
    var from = initialStream.getAttribute('from');
    if (from != null) {
      _serverName = from;
    }
  }

  bool isOpened() {
    return state != XmppConnectionState.Closed &&
        state != XmppConnectionState.ForcefullyClosed &&
        state != XmppConnectionState.Closing &&
        state != XmppConnectionState.SocketOpening;
  }

  void write(message) {
    Log.xmppp_sending(message);
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
    Log.d(TAG, 'State: ${_state}');
  }

  XmppConnectionState get state => _state;

  void _processState(XmppConnectionState state) {
    if (state == XmppConnectionState.Authenticated) {
      authenticated = true;
      _openStream();
    }
  }

  void startSecureSocket() {
    Log.d(TAG, 'startSecureSocket');
    SecureSocket.secure(_socket, onBadCertificate: _validateBadCertificate)
        .then((secureSocket) {
      _socket = secureSocket;
      _socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .map(prepareStreamResponse)
          .listen(handleResponse,
              onError: (error) =>
                  {handleSecuredConnectionError(error.toString())},
              onDone: handleSecuredConnectionDone);
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
  }

  void doneParsingFeatures() {
    if (state == XmppConnectionState.SessionInitialized) {
      setState(XmppConnectionState.Ready);
    }
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
    Log.d(TAG, 'Handle connection done');
    handleCloseState();
  }

  void handleSecuredConnectionDone() {
    Log.d(TAG, 'Handle secured connection done');
    handleCloseState();
  }

  void handleConnectionError(String error) {
    handleCloseState();
  }

  void handleCloseState() {
    if (state == XmppConnectionState.WouldLikeToOpen) {
      setState(XmppConnectionState.Closed);
      connect();
    } else if (state != XmppConnectionState.Closing) {
      setState(XmppConnectionState.ForcefullyClosed);
    } else {
      setState(XmppConnectionState.Closed);
    }
  }

  void handleSecuredConnectionError(String error) {
    Log.d(TAG, 'Handle Secured Error  $error');
    handleCloseState();
  }

  bool isAsyncSocketState() => state == XmppConnectionState.SocketOpening ||
        state == XmppConnectionState.Closing;
}
