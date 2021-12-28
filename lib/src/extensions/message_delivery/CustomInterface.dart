import 'package:xmpp_stone/src/elements/XmppElement.dart';

abstract class CustomInterface {
  CustomInterface addCustom(String customString);
  XmppElement? getCustom();
}
