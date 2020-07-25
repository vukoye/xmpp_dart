import 'package:xmpp_stone/src/data/Jid.dart';

class XmppAccountSettings {
  String name;
  String username;
  String domain;
  String resource = '';
  String password;
  String host;
  int port;
  int totalReconnections = 3;
  int reconnectionTimeout = 1000;
  bool ackEnabled = true;

  XmppAccountSettings(this.name, this.username, this.domain, this.password, this.port, {this.host, this.resource} );

  Jid get fullJid => Jid(username, domain, resource);

  static XmppAccountSettings fromJid(String jid, String password) {
    var fullJid = Jid.fromFullJid(jid);
    return XmppAccountSettings(jid, fullJid.local, fullJid.domain, password, 5222);
  }
}
