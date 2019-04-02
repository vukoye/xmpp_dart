
import 'dart:async';

import 'package:xmppstone/src/Connection.dart';
import 'package:xmppstone/src/data/Jid.dart';
import 'package:xmppstone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmppstone/src/elements/stanzas/PresenceStanza.dart';
import 'package:xmppstone/src/presence/PresenceApi.dart';

class PresenceManager implements PresenceApi {
  Connection _connection;

  List<PresenceStanza> requests = List<PresenceStanza>();

  StreamController<PresenceData> _presenceStreamController = new StreamController<PresenceData>.broadcast();

  StreamController<SubscriptionEvent> _subscribeStreamController = new StreamController<SubscriptionEvent>.broadcast();
  StreamController<PresenceErrorEvent> _errorStreamController = new StreamController<PresenceErrorEvent>.broadcast();

  PresenceData _selfPresence = PresenceData(PresenceShowElement.CHAT, "", null);

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

  static Map<Connection, PresenceManager> instances = Map<Connection, PresenceManager>();

  static getInstance(Connection connection) {
    PresenceManager manager = instances[connection];
    if (manager == null) {
      manager = PresenceManager(connection);
      instances[connection] = manager;
    }
    return manager;
  }

  PresenceManager(Connection this._connection) {
    _connection.inStanzasStream
        .where((abstractStanza)  => abstractStanza is PresenceStanza)
        .map((stanza) => stanza as PresenceStanza)
        .listen(_processPresenceStanza);
    _connection.connectionStateStream.listen(_connectionStateHandler);
  }

  @override
  void acceptSubscription(Jid to) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    presenceStanza.type = PresenceType.SUBSCRIBED;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void declineSubscription(Jid to) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    presenceStanza.type = PresenceType.UNSUBSCRIBED;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void sendDirectPresence(PresenceData presence, Jid to) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.toJid = to;
    presenceStanza.show = presence.showElement;
    presenceStanza.status = presence.status;
    _connection.writeStanza(presenceStanza);
  }

  @override
  void sendPresence(PresenceData presence) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.show = presence.showElement;
    presenceStanza.status = presence.status;
    _connection.writeStanza(presenceStanza);
  }

  @override
  void subscribe(Jid to) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    presenceStanza.type = PresenceType.SUBSCRIBE;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  @override
  void unsubscribe(Jid to) {
    PresenceStanza presenceStanza = new PresenceStanza();
    presenceStanza.id = _getPresenceId();
    presenceStanza.toJid = to;
    presenceStanza.type = PresenceType.UNSUBSCRIBE;
    requests.add(presenceStanza);
    _connection.writeStanza(presenceStanza);
  }

  void _processPresenceStanza(PresenceStanza presenceStanza) {
    if (presenceStanza.type == null) {
      //presence event
      _presenceStreamController.add(new PresenceData(presenceStanza.show, presenceStanza.status, presenceStanza.fromJid));
    } else {

      switch(presenceStanza.type) {
        case PresenceType.SUBSCRIBE:
          SubscriptionEvent subscriptionEvent = new SubscriptionEvent();
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
          SubscriptionEvent subscriptionEvent = new SubscriptionEvent();
          subscriptionEvent.type = SubscriptionEventType.ACCEPTED;
          subscriptionEvent.jid = presenceStanza.fromJid;
          _subscribeStreamController.add(subscriptionEvent);
          break;
        case PresenceType.UNSUBSCRIBED:
          SubscriptionEvent subscriptionEvent = new SubscriptionEvent();
          subscriptionEvent.type = SubscriptionEventType.DECLINED;
          subscriptionEvent.jid = presenceStanza.fromJid;
          _subscribeStreamController.add(subscriptionEvent);
          break;
        case PresenceType.UNAVAILABLE:
          break;
      }
    }
  }

  String _getPresenceId() {
    return "presence${AbstractStanza.getRandomId()}";
  }

  void _connectionStateHandler(XmppConnectionState state) {
    if (state == XmppConnectionState.DoneServiceDiscovery) {
      //_getRosters();
      _sendInitialPresence();
    }
  }

  void _sendInitialPresence() {
    PresenceStanza initialPresence = new PresenceStanza();
    _connection.writeStanza(initialPresence);
  }

  void _handleErrorEvent(PresenceStanza presenceStanza) {
    //TODO Add more handling
    PresenceErrorEvent errorEvent = new PresenceErrorEvent();
    errorEvent.presenceStanza = presenceStanza;
    var errorTypeString = presenceStanza.getChild('error')?.getAttribute('type')?.value;
    if (errorTypeString != null && errorTypeString == 'modify') {
      errorEvent.type = PresenceErrorType.MODIFY;
    }
    _errorStreamController.add(errorEvent);
  }
}
