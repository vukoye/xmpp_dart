import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:synchronized/synchronized.dart';
import 'package:universal_io/io.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xmpp_stone/src/ReconnectionManager.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';
import 'package:xmpp_stone/src/features/servicediscovery/CarbonsNegotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import 'package:xmpp_stone/src/features/servicediscovery/ServiceDiscoveryNegotiator.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamManagmentModule.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'connection/XmppWebsocketApi.dart'
    if (dart.library.io) 'connection/XmppWebsocketIo.dart'
    if (dart.library.html) 'connection/XmppWebsocketHtml.dart' as xmppSocket;

enum XmppConnectionState {
  Idle,
  Closed,
  SocketOpening,
  SocketOpened,
  DoneParsingFeatures,
  StartTlsFailed,
  AuthenticationNotSupported,
  PlainAuthentication,
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
  WouldLikeToClose,
}

class Connection {
  var lock = Lock(reentrant: true);

  static String TAG = 'Connection';

  static Map<String, Connection> instances = {};

  XmppAccountSettings account;

  StreamManagementModule? streamManagementModule;

  Jid get serverName {
    if (_serverName != null) {
      return Jid.fromFullJid(_serverName!);
    } else {
      return Jid.fromFullJid(fullJid.domain); //todo move to account.domain!
    }
  } //move this somewhere

  String? _serverName;

  static Connection getInstance(XmppAccountSettings account) {
    var connection = instances[account.fullJid.userAtDomain];
    if (connection == null) {
      connection = Connection(account);
      instances[account.fullJid.userAtDomain] = connection;
    }
    return connection;
  }

  static void removeInstance(XmppAccountSettings account) {
    instances.removeWhere((key, value) => key == account.fullJid.userAtDomain);
  }

  String? errorMessage;

  bool authenticated = false;

  final StreamController<AbstractStanza?> _inStanzaStreamController =
      StreamController.broadcast();

  final StreamController<AbstractStanza> _outStanzaStreamController =
      StreamController.broadcast();

  final StreamController<Nonza> _inNonzaStreamController =
      StreamController.broadcast();

  final StreamController<Nonza> _outNonzaStreamController =
      StreamController.broadcast();

  final StreamController<XmppConnectionState> _connectionStateStreamController =
      StreamController.broadcast();

  Stream<AbstractStanza?> get inStanzasStream {
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

  Jid get fullJid => account.fullJid;

  late ConnectionNegotiatorManager connectionNegotatiorManager;

  void fullJidRetrieved(Jid jid) {
    account.resource = jid.resource;
  }

  xmppSocket.XmppWebSocket? _socket;

  // for testing purpose
  set socket(xmppSocket.XmppWebSocket? value) {
    _socket = value;
  }

  XmppConnectionState _state = XmppConnectionState.Idle;

  ReconnectionManager? reconnectionManager;

  Connection(this.account) {
    RosterManager.getInstance(this);
    PresenceManager.getInstance(this);
    MessageHandler.getInstance(this);
    PingManager.getInstance(this);
    connectionNegotatiorManager = ConnectionNegotiatorManager(this, account);
    reconnectionManager = ReconnectionManager(this);
  }

  void _openStream() {
    var streamOpeningString = _socket?.getStreamOpeningElement(fullJid.domain);
    write(streamOpeningString);
  }

  String restOfResponse = '';

  String extractWholeChild(String response) {
    return response;
  }

  String prepareStreamResponse(String response) {
    Log.xmppp_receiving(response);
    var response1 = extractWholeChild(restOfResponse + response);
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

    // Ignore declarations to avoid parsing problem
    final xmlDeclarationMatcher = RegExp(r'<\?xml [^?]*\?>');
    // final xmlDeclarations = xmlDeclarationMatcher.allMatches(response1);
    // response1 = xmlDeclarations.map((e) => e[0]).join('') + '\n' + response1.replaceAll(xmlDeclarationMatcher, '');
    response1 = response1.replaceAll(xmlDeclarationMatcher, '');
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
    connectionNegotatiorManager.init();
    setState(XmppConnectionState.SocketOpening);
    try {
      var socket = xmppSocket.createSocket();

      return await socket
          .connect(
        account.host ?? account.domain,
        account.port,
        wsProtocols: account.wsProtocols,
        wsPath: account.wsPath,
        map: prepareStreamResponse,
      )
          .then((socket) {
        // if not closed in meantime
        if (_state != XmppConnectionState.Closed) {
          setState(XmppConnectionState.SocketOpened);
          _socket = socket;
          socket.listen(handleResponse, onDone: handleConnectionDone);
          _openStream();
        } else {
          Log.d(TAG, 'Closed in meantime');
          socket.close();
        }
      });
    } catch (error) {
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
          _socket!.write('</stream:stream>');
        } on Exception {
          Log.d(TAG, 'Socket already closed');
        }
      }
      authenticated = false;
    }
  }

  /// Dispose of the connection so stops all activities and cannot be re-used.
  /// For the connection to be garbage collected.
  ///
  /// If the Connection instance was created with [getInstance],
  /// you must also call [Connection.removeInstance] after calling [dispose].
  ///
  /// If you intend to re-use the connection later, consider just calling [close] instead.
  void dispose() {
    close();
    RosterManager.removeInstance(this);
    PresenceManager.removeInstance(this);
    MessageHandler.removeInstance(this);
    PingManager.removeInstance(this);
    ServiceDiscoveryNegotiator.removeInstance(this);
    StreamManagementModule.removeInstance(this);
    CarbonsNegotiator.removeInstance(this);
    MAMNegotiator.removeInstance(this);
    reconnectionManager?.close();
    _socket?.close();
  }

  bool startMatcher(xml.XmlElement element) {
    var name = element.name.local;
    return name == 'stream';
  }

  bool stanzaMatcher(xml.XmlElement element) {
    var name = element.name.local;
    return name == 'iq' || name == 'message' || name == 'presence';
  }

  bool nonzaMatcher(xml.XmlElement element) {
    var name = element.name.local;
    return name != 'iq' && name != 'message' && name != 'presence';
  }

  bool featureMatcher(xml.XmlElement element) {
    var name = element.name.local;
    return (name == 'stream:features' || name == 'features');
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
      Log.v(TAG, 'full response = $fullResponse');
      _unparsedXmlResponse = '';
    } else {
      fullResponse = response;
    }

    if (fullResponse.isNotEmpty) {
      xml.XmlNode? xmlResponse;
      try {
        xmlResponse = xml.XmlDocument.parse(
                fullResponse.replaceAll(RegExp(r'<\?(xml.+?)\>'), ''))
            .firstChild;
      } catch (e) {
        _unparsedXmlResponse += fullResponse.substring(
            0, fullResponse.length - 13); //remove  xmpp_stone end tag
        xmlResponse = xml.XmlElement(xml.XmlName('error'));
      }

      //TODO: Improve parser for children only
      xmlResponse!.descendants
          .whereType<xml.XmlElement>()
          .where((element) => startMatcher(element))
          .forEach((element) => processInitialStream(element));

      xmlResponse.childElements
          .where((element) => stanzaMatcher(element))
          .map((xmlElement) => StanzaParser.parseStanza(xmlElement))
          .forEach((stanza) => _inStanzaStreamController.add(stanza));

      xmlResponse.descendants
          .whereType<xml.XmlElement>()
          .where((element) => featureMatcher(element))
          .forEach((feature) =>
              connectionNegotatiorManager.negotiateFeatureList(feature));

      //TODO: Probably will introduce bugs!!!
      xmlResponse.childElements
          .where((element) => nonzaMatcher(element))
          .map((xmlElement) => Nonza.parse(xmlElement))
          .forEach((nonza) => _inNonzaStreamController.add(nonza));
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
      _socket!.write(message);
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
    Log.d(TAG, 'State: $_state');
  }

  XmppConnectionState get state {
    return _state;
  }

  void _processState(XmppConnectionState state) {
    if (state == XmppConnectionState.Authenticated) {
      authenticated = true;
      _openStream();
    } else if (state == XmppConnectionState.Closed ||
        state == XmppConnectionState.ForcefullyClosed) {
      authenticated = false;
    }
  }

  void processError(xml.XmlDocument xmlResponse) {
    //todo find error stanzas
  }

  void startSecureSocket() {
    Log.d(TAG, 'startSecureSocket');

    _socket!
        .secure(onBadCertificate: _validateBadCertificate)
        .then((secureSocket) {
      if (secureSocket == null) return;

      secureSocket
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
    var list = element.attributes.firstWhereOrNull((attr) =>
        attr.name.local == attribute.name.local &&
        attr.value == attribute.value);
    return list != null;
  }

  void sessionReady() {
    setState(XmppConnectionState.SessionInitialized);
    //now we should send presence
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

  bool isTlsRequired() {
    return xmppSocket.isTlsRequired();
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
    StreamManagementModule.removeInstance(this);
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

  bool isAsyncSocketState() {
    return state == XmppConnectionState.SocketOpening ||
        state == XmppConnectionState.Closing;
  }
}
