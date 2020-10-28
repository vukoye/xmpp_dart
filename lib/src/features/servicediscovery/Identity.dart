import 'package:xmpp_stone/src/elements/XmppElement.dart';

import '../../elements/nonzas/Nonza.dart';

class Identity extends Nonza {
  String get category {
    return getAttribute('category')?.value;
  }

  String get type {
    return getAttribute('type')?.value;
  }

  String get name {
    return getAttribute('name')?.value ?? "INVALID";
  }
}
