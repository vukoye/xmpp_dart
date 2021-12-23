import 'package:xmpp_stone/src/elements/XmppElement.dart';

abstract class TimeInterface {
  TimeInterface addTime(int timeMilliseconds);
  XmppElement? getTime();
}
