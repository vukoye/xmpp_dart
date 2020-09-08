import 'package:xmpp_stone/src/data/Jid.dart';

class Buddy {
  SubscriptionType _subscriptionType;

  String _name;

  Jid _accountJid;

  Jid get accountJid => _accountJid;

  set accountJid(Jid value) {
    _accountJid = value;
  }

  SubscriptionType get subscriptionType => _subscriptionType;

  set subscriptionType(SubscriptionType value) {
    _subscriptionType = value;
  }

  Jid _jid;

  Jid get jid => _jid;

  Buddy(Jid jid) {
    _jid = jid;
  }

  @override
  String toString() {
    return _jid.fullJid;
  }

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  static SubscriptionType typeFromString(String typeString) {
    switch (typeString) {
      case 'none':
        return SubscriptionType.NONE;
        break;
      case 'to':
        return SubscriptionType.TO;
        break;
      case 'from':
        return SubscriptionType.FROM;
        break;
      case 'both':
        return SubscriptionType.BOTH;
        break;
    }
    return null;
  }
}

enum SubscriptionType { NONE, TO, FROM, BOTH }
