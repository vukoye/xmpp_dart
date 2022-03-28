import 'dart:async';

import 'models/TestUser.dart';
import 'models/xmpp_communication_callback.dart';
import 'user.dart';
import 'users_connection.dart';

final String TAG = 'example';
final String roomName = 'test7';

void main(List<String> arguments) async {
  final UsersConnection users = await initRemoteUser();
  final result = await sendMassivePersonalMessageScenario(users);
  if (result) {
    print('sendMassivePersonalMessageScenario work');
  }
  // await sendMessageScenario(users);
  await createGroupScenario(users);
  // await removeMembersInGroupScenario(users);
  // await addAdminsInGroupScenario(users);
  // await removeAdminsInGroupScenario(users);
}

Future<bool> sendMassivePersonalMessageScenario(UsersConnection users) async {
  var completer = Completer<bool>();
  final keys = users.users.keys.toList();
  final user1 = users.users[keys[0]];
  final user2 = users.users[keys[1]];
  user1?.xmppCallback!.onMessage = (message) {
    // print('${user1.name} vin receive message from sendMessageScenario ${message.message!.body}');
  };
  user2?.xmppCallback!.onMessage = (message) {
    // print('${user2.name} receive message from sendMessageScenario ${message.message!.body}');
    if (!completer.isCompleted &&
        message.message!.body == 'I miss you. jub jub.') {
      completer.complete(true);
    }
  };
  final n = 10;
  for (var i = 0; i < n; i++) {
    if (i == n - 1) {
      user1?.sendMessage(message: 'I miss you. jub jub.', user: user2!);
    }
    user1?.sendMessage(message: i.toString(), user: user2!);
    user2?.sendMessage(message: i.toString(), user: user1!);
  }

  return completer.future;
}

// user A send message to user B
Future<void> sendMessageScenario(UsersConnection users) async {
  var completer = Completer<void>();
  final keys = users.users.keys.toList();
  final user1 = users.users[keys[0]];
  final user2 = users.users[keys[1]];
  user1?.xmppCallback!.onMessage = (message) {
    // print('${user1.name} vin receive message from sendMessageScenario ${message.message!.body}');
  };
  user2?.xmppCallback!.onMessage = (message) {
    // print('${user2.name} receive message from sendMessageScenario ${message.message!.body}');
    if (!completer.isCompleted &&
        message.message!.body == 'I miss you. jub jub.') {
      completer.complete();
    }
  };

  user1?.sendMessage(message: 'I miss you. jub jub.', user: user2!);
  return completer.future;
}

// create group with 2 user
Future<void> createGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];
  final keys = users.users.keys.toList();
  final user = users.users[keys[0]]; // key 1

  users.users.forEach((key, value) {
    if (key != user?.name) {
      usersJid.add(users.users[key]?.jid ?? '');
    }
  });
  await user?.createGroup(roomName: roomName, usersJid: usersJid);
  final members = await user?.getMembers(roomName: roomName);
  final admins = await user?.getAdmins(roomName: roomName);
  final owners = await user?.getOwners(roomName: roomName);

  return Future.value();
}

// remove a member from group
Future<void> removeMembersInGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];

  final keys = users.users.keys.toList();
  final user = users.users[keys[0]]; // key
  final removeUser = users.users[keys[1]];

  usersJid.add(removeUser?.jid ?? '');

  final result =
      await user?.removeMembersInGroup(roomName: roomName, usersJid: usersJid);
  if (result!) {
    user?.sendCustomGroupMessage(roomName: roomName);
  }
  // send notify the group when remove someone from group
  final members = await user?.getMembers(roomName: roomName);
  final admins = await user?.getAdmins(roomName: roomName);
  final owners = await user?.getOwners(roomName: roomName);

  return Future.value();
}

// add admin from group
Future<void> addAdminsInGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];

  final keys = users.users.keys.toList();
  final user = users.users[keys[0]]; // key
  final adminUser = users.users[keys[2]];
  final adminUser1 = users.users[keys[3]];

  usersJid.add(adminUser?.jid ?? '');
  usersJid.add(adminUser1?.jid ?? '');

  await user?.addAdminsInGroup(roomName: roomName, usersJid: usersJid);
  final members = await user?.getMembers(roomName: roomName);
  final admins = await user?.getAdmins(roomName: roomName);
  final owners = await user?.getOwners(roomName: roomName);
  return Future.value();
}

// remove admin from group
Future<void> removeAdminsInGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];

  final keys = users.users.keys.toList();
  final user = users.users[keys[0]]; // key
  final adminUser = users.users[keys[3]];

  usersJid.add(adminUser?.jid ?? '');

  await user?.addAdminsInGroup(roomName: roomName, usersJid: usersJid);
  final members = await user?.getMembers(roomName: roomName);
  final admins = await user?.getAdmins(roomName: roomName);
  final owners = await user?.getOwners(roomName: roomName);
  return Future.value();
}

Future<UsersConnection> initUser() async {
  // final XMPPClientManager xmppClientManager;
  var completer = Completer<UsersConnection>();

  Map<String, String> users = {
    '1647-240077-542380-47b2339c2a355ed6': 'kuldeep',
    // '1645-172186-380626-a86b135e92b91a62': 'Pandu',
    // '1645-172185-192393-a58cddac1966a202': 'Mattiase',
    // '1645-172183-991847-3fa4f971a33f74dd': 'Sean',
    // '1645-172182-845682-ded03d039f3ecaf9': 'Tiyas',
    // '1645-172156-753026-d6cad65e2c7b218e': 'Adit',
    // '1645-172181-615357-3252671253d9ae63': 'Keisha',
    // '1645-172180-393902-d026f1e92f8d68c2': 'Ardian',
    // '1645-172179-340032-606f2653306f37d6': 'Raj',
    // '1645-172178-48241-6cc48db9ff97e5e4': 'Tamma',
    // '1645-172177-107955-0e0bd3d1f6cc27b1': 'Mateo', //28
  };

  UsersConnection usersConnection =
      UsersConnection(users: {}, xmppCallback: XmppCommunicationCallback());
  int countUserConnected = 0;
  var host = 'localhost';
  var password = 'password';

  users.forEach((key, value) {
    var atDomain = '${key}@${host}';
    var resource = '/${value}';
    var jid = '${atDomain}$resource';
    var user = User(
        name: value,
        jid: jid,
        password: password,
        phoneNumber: '',
        xmppCallback: XmppCommunicationCallback());
    user.connect(() {
      if (++countUserConnected == users.length) {
        completer.complete(usersConnection);
      }
    });
    usersConnection.users[value] = user;
  });

  return completer.future;
}

Future<UsersConnection> initRemoteUser() async {
  // final XMPPClientManager xmppClientManager;
  var completer = Completer<UsersConnection>();

  Map<String, User> users = TestUser().generateUsers(2);

  UsersConnection usersConnection =
      UsersConnection(users: {}, xmppCallback: XmppCommunicationCallback());
  int countUserConnected = 0;

  users.forEach((key, value) {
    var user = value;
    user.connect(() {
      if (++countUserConnected == users.length) {
        completer.complete(usersConnection);
      }
    });
    usersConnection.users[user.name] = user;
  });

  return completer.future;
}
