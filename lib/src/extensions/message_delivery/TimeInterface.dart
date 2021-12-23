import 'package:xmpp_stone_obelisk/src/elements/XmppElement.dart';

abstract class TimeInterface {
  TimeInterface addTime(int timeMilliseconds);
  XmppElement? getTime();
}
