import 'package:xmpp_stone/src/data/Jid.dart';

class XmppAccountSettings {
  String name;
  String username;
  String domain;
  String resource = "";
  String password;
  int port;

  XmppAccountSettings(this.name, this.username, this.domain, this.password, this.port);

  Jid get fullJid => Jid(username, domain, resource);

  static XmppAccountSettings fromJid(String jid, String password) {
    Jid fullJid = Jid.fromFullJid(jid);
    return XmppAccountSettings(jid, fullJid.local, fullJid.domain, password, 5222);
  }
}
