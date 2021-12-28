// import 'dart:async';

// import 'package:tuple/tuple.dart';
// import 'package:xmpp_stone/src/Connection.dart';
// import 'package:xmpp_stone/src/data/Jid.dart';
// import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
// import 'package:xmpp_stone/src/elements/XmppElement.dart';
// import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
// import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';

// class MessageDeliveryManager {
//   static Map<Connection, MessageDeliveryManager> instances =
//       <Connection, MessageDeliveryManager>{};

//   static MessageDeliveryManager getInstance(Connection connection) {
//     var manager = instances[connection];
//     if (manager == null) {
//       manager = MessageDeliveryManager(connection);
//       instances[connection] = manager;
//     }

//     return manager;
//   }

//   final Connection _connection;

//   MessageDeliveryManager(this._connection) {
//     _connection.connectionStateStream.listen(_connectionStateProcessor);
//     _connection.inStanzasStream.listen(_processStanza);
//   }

//   final Map<String?, Tuple2<IqStanza, Completer>> _myUnrespondedIqStanzas =
//       <String?, Tuple2<IqStanza, Completer>>{};

//   // final Map<String, MultiUserChat> _mucList = <String, MultiUserChat>{};

//   void _connectionStateProcessor(XmppConnectionState event) {}

//   // Map<String, MultiUserChat> getAllReceivedVCards() {
//   //   return _mucList;
//   // }

//   void init() {
//     print('Init ManageDeliveryManager');
//   }

//   // Try to discover the services
//   Future<String> discoverDeliveryFeature(Jid from, Jid to) {
//     var completer = Completer<String>();
//     var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET);
//     iqStanza.fromJid = _connection.fullJid;
//     iqStanza.toJid = Jid('', 'localhost', '');
//     var queryElement = XmppElement();
//     queryElement.name = 'query';
//     queryElement.addAttribute(
//         XmppAttribute('xmlns', 'http://jabber.org/protocol/disco#info'));
//     iqStanza.addChild(queryElement);
//     _myUnrespondedIqStanzas[iqStanza.id] = Tuple2(iqStanza, completer);
//     print(iqStanza.buildXmlString());
//     _connection.writeStanza(iqStanza);
//     return completer.future;
//   }

//   String? _handlediscoverDeliveryFeatureResponse(IqStanza stanza) {
//     var queryChild = stanza.getChild('query');
//     if (queryChild != null) {
//       var result = stanza.buildXmlString();
//       return result;
//     }
//     return null;
//   }

//   void _processStanza(AbstractStanza? stanza) {
//     print('Receive stanza:' + stanza!.buildXmlString());
//     if (stanza is IqStanza) {
//       var unrespondedStanza = _myUnrespondedIqStanzas[stanza.id];
//       if (_myUnrespondedIqStanzas[stanza.id] != null) {
//         print('Message Delivery Stanza type: ' + stanza.type.toString());
//         if (stanza.type == IqStanzaType.RESULT) {
//           var mucResult = _handlediscoverDeliveryFeatureResponse(stanza);
//           if (mucResult != null) {
//             unrespondedStanza!.item2.complete(mucResult);
//           }
//         } else if (stanza.type == IqStanzaType.ERROR) {
//           unrespondedStanza!.item2.complete(null);
//         }
//       }
//     }
//   }
// }
