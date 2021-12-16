import 'package:collection/src/iterable_extensions.dart';

class PrivacyListItem {
  PrivacyType? type;
  String? value;
  PrivacyAction action;
  int order = 0;
  List<PrivacyControlStanza>? controlStanzas;

  PrivacyListItem({
    this.type,
    this.value,
    required this.action,
    required this.order,
    this.controlStanzas,
  });
}

enum PrivacyType { JID, GROUP, SUBSCRIPTION }
enum PrivacyAction { ALLOW, DENY }
enum PrivacySubscriptionType { BOTH, TO, FROM }
enum PrivacyControlStanza { MESSAGE, IQ, PRESENCE_IN, PRESENCE_OUT }

