import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';

abstract class PingListener {
  void onPing(IqStanza? iqStanza);
}
