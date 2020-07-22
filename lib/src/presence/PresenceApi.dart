import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/PresenceStanza.dart';

abstract class PresenceApi {
  void sendPresence(PresenceData presence);

  void subscribe(Jid to);

  void unsubscribe(Jid to);

  void acceptSubscription(Jid to);

  void declineSubscription(Jid to);

  void sendDirectPresence(PresenceData presence, Jid to);

  void askDirectPresence(Jid to);
}

class PresenceData {
  PresenceShowElement showElement;
  String status;
  Jid jid; // if Jid is Null or self jid its self presence
  PresenceData(this.showElement, this.status, this.jid);
}

enum SubscriptionEventType { REQUEST, ACCEPTED, DECLINED }

class SubscriptionEvent {
  SubscriptionEventType type;
  Jid jid;
}

class PresenceErrorEvent {
  PresenceStanza presenceStanza;
  PresenceErrorType type;
}

enum PresenceErrorType { MODIFY }
