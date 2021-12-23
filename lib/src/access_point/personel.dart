import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChat.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class XMPPClientPersonel {
  String jid;
  String password;
  VCard? profile;
  List<Buddy>? buddies;
  List<MultiUserChat>? groups;
  XMPPClientPersonel(this.jid, this.password);
}