import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmpp_stone/src/presence/PresenceApi.dart';

class PresenceManager implements PresenceApi {
  final Connection _connection;

  List<PresenceStanza> requests = <PresenceStanza>[];

  final StreamController<PresenceData> _presenceStreamController = StreamController<PresenceData>.broadcast();

  final StreamController<SubscriptionEvent> _subscribeStreamController =
      StreamController<SubscriptionEvent>.broadcast();
  final StreamController<PresenceErrorEvent> _errorStreamController = StreamController<PresenceErrorEvent>.broadcast();

  PresenceData _selfPresence = PresenceData(PresenceShowElement.CHAT, '', null);

  PresenceData get selfPresence {
    _selfPresence.jid = _connection.fullJid;
    return _selfPresence;
  }

  set selfPresence(PresenceData value) {
    _selfPresence = value;
  }

  Stream<PresenceData> get presenceStream {
    return _presenceStreamController.stream;
  }

  Stream<SubscriptionEvent> get subscriptionStream {
    return _subscribeStreamController.stream;
  }

  Stream<PresenceErrorEvent> get errorStream {
    return _errorStreamController.stream;
  }

  static Map<Connection, PresenceManager> instances = <Connection, PresenceManager>{};

  static PresenceManager getInstance(Connection connection) {
    var manager = instances[connection];
    if (manager == null) {
      manager = PresenceManager(connection);
      instances[connection] = manager;
    }
    return manager;
  }

  PresenceManager(this._connection) {
    _connection.inStanzasStream
        .where((abstractStanza) => abstractStanza is PresenceStanza)
        .map((stanza) => stanza as PresenceStanza)
        .listen(_processPresenceStanza);
    _connection.connectionStateStream.listen(_connectionStateHandler);
  }

  @override
  void acceptSubscription(Jid to) {
    var presenceStanza = PresenceStanza.withType(PresenceType.SUBSCRIBED);
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void declineSubscription(Jid to) {
    var presenceStanza = PresenceStanza.withType(PresenceType.UNSUBSCRIBED);
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void sendDirectPresence(PresenceData presence, Jid to) {
    var presenceStanza = PresenceStanza();
    presenceStanza.toJid = to;
    presenceStanza.show = presence.showElement;
    presenceStanza.status = presence.status;
    _connection.writeStanza(presenceStanza);
  }

  @override
  void askDirectPresence(Jid to) {
    var presenceStanza = PresenceStanza.withType(PresenceType.PROBE);
    presenceStanza.toJid = to;
    presenceStanza.fromJid = _connection.fullJid;
    _connection.writeStanza(presenceStanza);
  }

  @override
  void sendPresence(PresenceData presence) {
    var presenceStanza = PresenceStanza();
    presenceStanza.show = presence.showElement;
    presenceStanza.status = presence.status;
    _connection.writeStanza(presenceStanza);
  }

  @override
  void subscribe(Jid to) {
    var presenceStanza = PresenceStanza.withType(PresenceType.SUBSCRIBE);
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void unsubscribe(Jid to) {
    var presenceStanza = PresenceStanza.withType(PresenceType.UNSUBSCRIBE);
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  void _processPresenceStanza(PresenceStanza presenceStanza) {
    if (presenceStanza.type == null) {
      //presence event
      _presenceStreamController.add(PresenceData(presenceStanza.show, presenceStanza.status, presenceStanza.fromJid));
    } else {
      switch (presenceStanza.type) {
        case PresenceType.SUBSCRIBE:
          var subscriptionEvent = SubscriptionEvent();
          subscriptionEvent.type = SubscriptionEventType.REQUEST;
          subscriptionEvent.jid = presenceStanza.fromJid;
          _subscribeStreamController.add(subscriptionEvent);
          break;
        case PresenceType.ERROR:
          _handleErrorEvent(presenceStanza);
          break;
        case PresenceType.UNSUBSCRIBE:
          break;
        case PresenceType.PROBE:
          break;
        case PresenceType.SUBSCRIBED:
          var subscriptionEvent = SubscriptionEvent();
          subscriptionEvent.type = SubscriptionEventType.ACCEPTED;
          subscriptionEvent.jid = presenceStanza.fromJid;
          _subscribeStreamController.add(subscriptionEvent);
          break;
        case PresenceType.UNSUBSCRIBED:
          var subscriptionEvent = SubscriptionEvent();
          subscriptionEvent.type = SubscriptionEventType.DECLINED;
          subscriptionEvent.jid = presenceStanza.fromJid;
          _subscribeStreamController.add(subscriptionEvent);
          break;
        case PresenceType.UNAVAILABLE:
          //presence event
          _presenceStreamController.add(PresenceData(PresenceShowElement.XA, 'Unavailable', presenceStanza.fromJid));
          break;
      }
    }
  }

  String _getPresenceId() {
    return 'presence${AbstractStanza.getRandomId()}';
  }

  void _connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.Ready) {
      //_getRosters();
      _sendInitialPresence();
    }
  }

  void _sendInitialPresence() {
    var initialPresence = PresenceStanza();
    _connection.writeStanza(initialPresence);
  }

  void _handleErrorEvent(PresenceStanza presenceStanza) {
    //TODO Add more handling
    var errorEvent = PresenceErrorEvent();
    errorEvent.presenceStanza = presenceStanza;
    var errorTypeString = presenceStanza.getChild('error')?.getAttribute('type')?.value;
    if (errorTypeString != null && errorTypeString == 'modify') {
      errorEvent.type = PresenceErrorType.MODIFY;
    }
    _errorStreamController.add(errorEvent);
  }
}
