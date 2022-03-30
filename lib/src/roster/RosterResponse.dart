import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';
import 'package:xmpp_stone/src/roster/Buddy.dart';

abstract class RosterResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
}

class QueryRosterResponse extends RosterResponse {
  late Map<Jid, Buddy> rosterMap;

  static QueryRosterResponse parse(
      AbstractStanza stanza, Connection? _connection) {
    final response = BaseResponse.parseError(stanza);

    final _response = QueryRosterResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      // Parse further
      final Map<Jid, Buddy> _rosterMap = {};
      var xmppElement = stanza.getChild('query');
      if (xmppElement != null &&
          xmppElement.getNameSpace() == 'jabber:iq:roster') {
        xmppElement.children.forEach((child) {
          if (child!.name == 'item') {
            var jid = Jid.fromFullJid(child.getAttribute('jid')!.value!);
            var name = child.getAttribute('name')?.value;
            var subscriptionString = child.getAttribute('subscription')?.value;
            var subscriptionRequestStatusString =
                child.getAttribute('ask')?.value;
            var buddy = Buddy(jid);
            buddy.name = name;
            buddy.accountJid = _connection!.fullJid;
            buddy.subscriptionType = Buddy.typeFromString(subscriptionString);
            buddy.subscriptionAskType =
                Buddy.typeAskFromString(subscriptionRequestStatusString);

            _rosterMap[jid] = buddy;
          }
        });
      }
      _response.rosterMap = _rosterMap;
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class SetRosterResponse extends RosterResponse {
  static SetRosterResponse parse(
      AbstractStanza stanza, Connection? _connection) {
    final response = BaseResponse.parseError(stanza);

    final _response = SetRosterResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}

class RemoveRosterResponse extends RosterResponse {
  static RemoveRosterResponse parse(
      AbstractStanza stanza, Connection? _connection) {
    final response = BaseResponse.parseError(stanza);

    final _response = RemoveRosterResponse();
    _response.response = response;
    if (response.runtimeType == BaseValidResponse) {
      _response.success = true;
    } else {
      _response.success = false;
    }

    return _response;
  }
}
