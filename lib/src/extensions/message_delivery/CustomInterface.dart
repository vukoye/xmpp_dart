import 'package:xmpp_stone_obelisk/src/elements/XmppElement.dart';

abstract class CustomInterface {
  CustomInterface addCustom(String customString);
  XmppElement? getCustom();
}
