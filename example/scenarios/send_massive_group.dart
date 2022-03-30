import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/access_point/manager_message_params.dart';

import '../models/xmpp_communication_callback.dart';
import '../simulation.dart';
import '../user.dart';
import '../users_connection.dart';
import 'scenario.dart';
import 'scenario_helper.dart';

class SendMassiveGroup extends Scenario with ScenarioHelper{
  UsersConnection users;
  String roomName = 'SendMassiveGroup';

  SendMassiveGroup({
    required this.users,
    required this.roomName,
  });

  @override
  void run() async {
    await createGroup(users);
    sendMassiveGroupMessageScenario(users, 0, 100);
    sendMassiveGroupMessageScenario(users, 5, 200);
    sendMassiveGroupMessageScenario(users, 10, 300);
    sendMassiveGroupMessageScenario(users, 15, 400);
    sendMassiveGroupMessageScenario(users, 20, 500);
    sendMassiveGroupMessageScenario(users, 25, 600);
    sendMassiveGroupMessageScenario(users, 30, 700);
    sendMassiveGroupMessageScenario(users, 35, 800);

  }
 
  Future<void> createGroup(UsersConnection users) async {
    List<String> usersJid = [];
    
    final keys = users.users.keys.toList();
    final user = users.users[keys[0]]; // key 1

    users.users.forEach((key, value) {
      if (key != user?.name) {
        usersJid.add(users.users[key]?.jid ?? '');
      }
    });
    await user?.createGroup(roomName: roomName, usersJid: usersJid);

    return Future.value();
  }

  void sendMassiveGroupMessageScenario(
      UsersConnection users, int userOffset, int nMessage) async {
    final keys = users.users.keys.toList();
    final user1 = getUserByIndex(users, keys, userOffset, 0);
    final user2 = getUserByIndex(users, keys, userOffset, 1);
    final user3 = getUserByIndex(users, keys, userOffset, 2);
    final user4 = getUserByIndex(users, keys, userOffset, 3);
    final user5 = getUserByIndex(users, keys, userOffset, 4);

    for (var i = 0; i < nMessage; i++) {
      // await Future.delayed(Duration(milliseconds: 200));
      performSendMessageToGroup(user1, i.toString());
      performSendMessageToGroup(user2, i.toString());
      performSendMessageToGroup(user3, i.toString());
      performSendMessageToGroup(user4, i.toString());
      performSendMessageToGroup(user5, i.toString());
    }
  }

  void performSendMessageToGroup(User user, String message) {
    try {
      if (user.xmppCallback!.onMessage == noFunc) {
        user.xmppCallback!.onMessage = (XMPPMessageParams message) {
          print(
              '${user.name} receive message from sendMessageScenario ${message.message!.fromJid?.fullJid} ${message.message!.body}');
        };
        user.xmppCallback!.onConnectionStatus = (XmppConnectionState state) {
          print('${user.name} onConnectionStatus ${state.toString()}');
        };
      }
      user.sendGroupMessage(
          roomName: roomName, message: message.padLeft(10, '0'));
    } catch (e) {
      print(e.toString());
    }
  }

  

}