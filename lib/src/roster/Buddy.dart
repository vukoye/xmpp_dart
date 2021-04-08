import 'package:xmpp_stone/src/data/Jid.dart';

class Buddy {
  SubscriptionType? subscriptionType;

  String? name;

  Jid? accountJid;

  Jid? _jid;

  Jid? get jid => _jid;

  Buddy(Jid jid) {
    _jid = jid;
  }

  @override
  String toString() {
    return _jid!.fullJid!;
  }

  static SubscriptionType? typeFromString(String? typeString) {
    switch (typeString) {
      case 'none':
        return SubscriptionType.NONE;
      case 'to':
        return SubscriptionType.TO;
      case 'from':
        return SubscriptionType.FROM;
      case 'both':
        return SubscriptionType.BOTH;
    }
    return null;
  }
}

enum SubscriptionType { NONE, TO, FROM, BOTH }
