import 'package:xmpp_stone/src/data/Jid.dart';

class Buddy {
  SubscriptionType? _subscriptionType;

  SubscriptionAskType? _subscriptionAskType;

  String? _name;

  Jid? _accountJid;

  Jid? get accountJid => _accountJid;

  set accountJid(Jid? value) {
    _accountJid = value;
  }

  SubscriptionType? get subscriptionType => _subscriptionType;

  set subscriptionType(SubscriptionType? value) {
    _subscriptionType = value;
  }

  SubscriptionAskType? get subscriptionAskType => _subscriptionAskType;

  set subscriptionAskType(SubscriptionAskType? value) {
    _subscriptionAskType = value;
  }

  Jid? _jid;

  Jid? get jid => _jid;

  Buddy(Jid jid) {
    _jid = jid;
  }

  @override
  String toString() {
    return _jid!.fullJid!;
  }

  String? get name => _name;

  set name(String? value) {
    _name = value;
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

  static SubscriptionAskType? typeAskFromString(String? typeString) {
    switch (typeString) {
      case 'none':
        return SubscriptionAskType.NONE;
      case 'subscribe':
        return SubscriptionAskType.SUBSCRIBE;
    }
    return SubscriptionAskType.NA;
  }
}

enum SubscriptionType { NONE, TO, FROM, BOTH }

enum SubscriptionAskType { NA, NONE, SUBSCRIBE }
