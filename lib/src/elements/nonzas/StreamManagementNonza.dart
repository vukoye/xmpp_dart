import 'dart:developer';

import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';

class StreamNonza extends Nonza {
  static String NAME = 'sm';
  static String XMLNS = 'urn:xmpp:sm:3';

  static bool match(Nonza nonza) {
    log('Stream Nonza is:-->>>${nonza.buildXmlString()}');
    return (nonza.buildXmlString().contains('features') &&
        nonza.buildXmlString().contains('bind') &&
        nonza.buildXmlString().contains('session') &&
        nonza.buildXmlString().contains('register') &&
        nonza.buildXmlString().contains('sm'));
  }

  StreamNonza() {
    name = NAME;
  }
}
