
import 'package:xmppstone/src/data/Jid.dart';

class XmppAccount {
  String name;
  String username;
  String domain;
  String resource = "";
  String password;
  int port;

  XmppAccount(this.name, this.username, this.domain, this.password, this.port);

  get fullJid => Jid(username, domain, resource);


  static XmppAccount fromJid(String jid, String password) {
    Jid fullJid = Jid.fromFullJid(jid);
    return XmppAccount(jid, fullJid.local, fullJid.domain, password, 5222);
  }
}