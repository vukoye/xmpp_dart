import 'package:xmpp_stone/src/data/Jid.dart';

abstract class LastActivityApi {
  void askLastActivity(Jid to);
}
