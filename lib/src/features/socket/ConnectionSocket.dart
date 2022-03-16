// import 'dart:async';
// import 'dart:io';

// import 'package:xmpp_stone/xmpp_stone.dart';

// class ConnectionSocket {
//   DateTime connectedAt;
//   String id;
//   Socket? socket;
//   ConnectionSocket({this.socket, required this.connectedAt, required this.id});

//   static List<ConnectionSocket?> instances = [];

//   void setSocket(Socket? _socket) {
//     socket = _socket;
//   }

//   static void dispose(instanceId) async {
//     final instanceById =
//         instances.where((element) => element!.id == instanceId);
//     if (instanceById.isNotEmpty) {
//       final olderInstances = instances.where((element) =>
//           element!.connectedAt.isBefore(instanceById.first!.connectedAt));
//       olderInstances.forEach((instance) async {
//         try {
//           instance!.socket!.write('</stream:stream>');
//           await instance.socket!.flush();
//           await instance.socket!.close();
//         } catch (e) {
//           print(e);
//         }
//       });

//       final olderIds = olderInstances.map<String>((e) => e!.id).toList();
//       instances = instances
//           .where((element) => !olderIds.contains(element!.id))
//           .toList();
//     }
//   }

//   static ConnectionSocket? hasInstance() {
//     return instances.first;
//   }

//   static Future<ConnectionSocket> getInstance(XmppAccountSettings account,
//       {forceNew = false}) async {
//     if (instances.isEmpty || forceNew) {
//       final newId = AbstractStanza.getRandomId();
//       final socket =
//           await Socket.connect(account.host ?? account.domain, account.port)
//               .then((socket) => socket, onError: (error, stack) {
//         Timer(const Duration(milliseconds: 200), () {
//           ConnectionSocket.dispose(newId);
//         });
//       });
//       instances.insert(
//           0,
//           ConnectionSocket(
//               socket: socket, connectedAt: DateTime.now(), id: newId));
//     }
//     return instances.first!;
//   }
// }
