import 'package:xmpp_stone_obelisk/xmpp_stone_obelisk.dart';

enum ReceiptRequestType { NONE, REQUEST, RECEIVED }

abstract class ReceiptInterface {
  ReceiptInterface addRequestReceipt();
  ReceiptInterface addReceivedReceipt();
  XmppElement? getRequestReceipt();
  XmppElement? getReceivedReceipt();
}
