// import 'dart:io';
//
// import 'package:mockito/mockito.dart';
// import 'package:test/test.dart';
// import 'package:xmpp_stone/src/Connection.dart';
// import 'package:xmpp_stone/src/account/XmppAccountSettings.dart';
// import 'package:xmpp_stone/src/features/ConnectionNegotatiorManager.dart';
// import 'package:xml/xml.dart' as xml;
//
// class MockConnection extends Mock implements Connection {}
//
// class MockSocket extends Mock implements Socket {}
//
// void main() {
//   group('connection tests plain authentication', () {
//     final mockSocket = MockSocket();
//     final connection = Connection(XmppAccountSettings.fromJid("test@test.com", "test"));
//     connection.socket = mockSocket;
//     final manager = ConnectionNegotatiorManager(connection, "");
//     final featuresTest = """
//     <stream:features>
//     <auth xmlns="http://jabber.org/features/iq-auth"/>
//     <register xmlns="http://jabber.org/features/iq-register"/>
//     <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
//         <mechanism>SCRAM-SHA-1</mechanism>
//         <mechanism>PLAIN</mechanism>
//         <mechanism>ANONYMOUS</mechanism>
//     </mechanisms>
//     <ver xmlns="urn:xmpp:features:rosterver"/>
//     <starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>
//     <compression xmlns="http://jabber.org/features/compress">
//         <method>zlib</method>
//     </compression>
// </stream:features>
// """;
//     final xmlResponse = xml.parse(featuresTest);
//     xmlResponse.descendants
//         .whereType<xml.XmlElement>()
//         .forEach((feature) => manager.negotiateFeatureList(feature));
//   });
// }
