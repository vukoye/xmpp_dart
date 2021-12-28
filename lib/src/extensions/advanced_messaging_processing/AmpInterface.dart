import 'package:xmpp_stone/xmpp_stone.dart';

/// Inspired by this XEP-0079: https://xmpp.org/extensions/xep-0079.html
/// https://xmpp.org/extensions/attic/jep-0079-1.0.html

abstract class AmpInterface {
  AmpInterface addAmpDeliverDirect();
  XmppElement? getAmp();
  bool isAmpDeliverDirect();
  bool isAmpDeliverStore();
}
