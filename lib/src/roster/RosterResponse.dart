// import 'package:xmpp_stone/src/response/base_response.dart';
// import 'package:xmpp_stone/xmpp_stone.dart';

// abstract class ResponseResponse {
//   late bool success;
//   late BaseResponse response;
// }

// class QueryRosterResponse extends ResponseResponse {
//   late Map<Jid, Buddy> rosterMap;

//   static QueryRosterResponse parse(
//       AbstractStanza stanza, Connection? _connection) {
//     final response = BaseResponse.parseError(stanza);

//     final _response = QueryRosterResponse();
//     _response.response = response;
//     if (response.runtimeType == BaseValidResponse) {
//       // Parse further
//       final Map<Jid, Buddy> _rosterMap = {};
//       var xmppElement = stanza.getChild('query');
//       if (xmppElement != null &&
//           xmppElement.getNameSpace() == 'jabber:iq:roster') {
//         xmppElement.children.forEach((child) {
//           if (child!.name == 'item') {
//             var jid = Jid.fromFullJid(child.getAttribute('jid')!.value!);
//             var name = child.getAttribute('name')?.value;
//             var subscriptionString = child.getAttribute('subscription')?.value;
//             var subscriptionRequestStatusString =
//                 child.getAttribute('ask')?.value;
//             var buddy = Buddy(jid);
//             buddy.name = name;
//             buddy.accountJid = _connection!.fullJid;
//             buddy.subscriptionType = Buddy.typeFromString(subscriptionString);
//             buddy.subscriptionAskType =
//                 Buddy.typeAskFromString(subscriptionRequestStatusString);

//             _rosterMap[jid] = buddy;
//           }
//         });
//       }
//       _response.rosterMap = _rosterMap;
//       _response.success = true;
//     } else {
//       _response.success = false;
//     }

//     return _response;
//   }
// }
