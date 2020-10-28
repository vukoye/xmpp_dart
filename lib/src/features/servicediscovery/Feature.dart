import 'package:xmpp_stone/src/elements/XmppElement.dart';

import '../../elements/nonzas/Nonza.dart';

class Feature extends Nonza {

  Feature() {
    name = 'feature';
  }
  String get xmppVar {
    return getAttribute('var')?.value;
  }
}
