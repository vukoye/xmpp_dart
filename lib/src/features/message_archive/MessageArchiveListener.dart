import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';

abstract class MessageArchiveListener {
  void onFinish(IqStanza? iqStanza);
}
