
class Jid {

  String _local = "";
  String _domain = "";
  String _resource = "";

  Jid(String local, String domain, String resource) {
    _local = local;
    _domain = domain;
    _resource = resource;
  }

  String get local => _local;
  String get domain => _domain;
  String get resource => _resource;
  String get fullJid {
    if (local != null && domain != null && resource != null && local.isNotEmpty && domain.isNotEmpty && resource.isNotEmpty)
      return "$_local@$_domain/$_resource";
    if (local == null || local.isEmpty) {
      return _domain;
    }
    if (resource == null || resource.isEmpty) {
      return"$_local@$_domain";
    }
  }
  String get userAtDomain  {
    if (local != null && local.isNotEmpty) return "$_local@$_domain";
    return _domain;
  }

  static Jid fromFullJid(String fullJid) {
    RegExp exp = new RegExp(r"^((.*?)@)?([^/@]+)(/(.*))?$");
    Iterable<Match> matches = exp.allMatches(fullJid);
    var match = matches.first;
    if (match != null) {
      return Jid(match[2], match[3], match[5]);
    } else return InvalidJid();
  }
}

class InvalidJid extends Jid {
  InvalidJid() : super('', '', '') {

  }
}