import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

class Jid {
  String? _local;
  String? _domain;
  String? _resource;

  Jid(String? local, String? domain, String? resource) {
    _local = local;
    _domain = domain;
    _resource = resource;
  }

  @override
  bool operator ==(other) {
    return other is Jid &&
        local == other.local &&
        domain == other.domain &&
        resource == other.resource;
  }

  String get local => _local ?? '';

  String get domain => _domain ?? '';

  String get resource => _resource ?? '';

  String get fullJid {
    if (local.isNotEmpty &&
        domain.isNotEmpty &&
        resource.isNotEmpty) {
      return '$_local@$_domain/$_resource';
    }
    if (local.isEmpty) {
      return domain;
    }
    if (resource.isEmpty) {
      return '$_local@$_domain';
    }
    return '';
  }

  String get userAtDomain {
    if (local.isNotEmpty) return '$_local@$_domain';
    return domain;
  }

  bool isValid() {
    return local.isNotEmpty &&
        domain.isNotEmpty;
  }

  static Jid fromFullJid(String fullJid) {
    var exp = RegExp(r'^((.*?)@)?([^/@]+)(/(.*))?$');
    Iterable<Match> matches = exp.allMatches(fullJid);
    var match = matches.firstOrNull;
    if (match != null) {
      return Jid(match[2], match[3], match[5]);
    } else {
      return InvalidJid();
    }
  }

  @override
  int get hashCode {
    return hash3(_local, _domain, _resource);
  }
}

class InvalidJid extends Jid {
  InvalidJid() : super('', '', '');
}
