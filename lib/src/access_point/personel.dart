import 'package:xmpp_stone_obelisk/xmpp_stone_obelisk.dart';

class XMPPClientPersonel {
  String jid;
  String password;
  VCard? profile;
  List<Buddy>? buddies;
  List<GroupChatroom>? groups;
  XMPPClientPersonel(this.jid, this.password);
}
