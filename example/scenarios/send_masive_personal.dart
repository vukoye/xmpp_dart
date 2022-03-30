import 'dart:async';
import 'dart:convert';

import 'package:xmpp_stone/src/Connection.dart';

import '../models/xmpp_communication_callback.dart';
import '../user.dart';
import '../users_connection.dart';
import 'scenario.dart';
import 'scenario_helper.dart';

/// Notes:
/// - Observe the receive message, and to know if the user receive the message correctly by filter console log with "receive"
/// - Observe the user connection state if some of the user kick out from the server by filter console log with "onConnectionStatus"
class SendMassivePersonal extends Scenario with ScenarioHelper{
  UsersConnection users;
  int batchSize;
  int nIteration;
  
  SendMassivePersonal({
    required this.users,
    required this.batchSize,
    required this.nIteration,
  });

  void run(){
    final msgList = [100,150,200,250,300,400,500,600,700,800,900];
    for (var i = 0; i < nIteration; i++) {
      sendMassivePersonalMessageScenario(users, batchSize * i, msgList[i] );
    }
    // sendMassivePersonalMessageScenario(users, 0, 100);
    // sendMassivePersonalMessageScenario(users, 10, 150);
    // sendMassivePersonalMessageScenario(users, 20, 200);
    // sendMassivePersonalMessageScenario(users, 30, 300);
    // sendMassivePersonalMessageScenario(users, 40, 400);
    // sendMassivePersonalMessageScenario(users, 50, 500);
    // sendMassivePersonalMessageScenario(users, 60, 600);
    // sendMassivePersonalMessageScenario(users, 70, 700);
    // sendMassivePersonalMessageScenario(users, 80, 700);
    // sendMassivePersonalMessageScenario(users, 90, 700);
  }

  Future<bool> sendMassivePersonalMessageScenario(
      UsersConnection users, int userOffset, int nMessage) async {
    var completer = Completer<bool>();
    final keys = users.users.keys.toList();
    final user1 = getUserByIndex(users, keys, userOffset, 0);
    final user2 = getUserByIndex(users, keys, userOffset, 1);
    user1.xmppCallback!.onMessage = (message) {
      // print('${user1.name} vin receive message from sendMessageScenario ${message.message!.body}');
    };

    user2.xmppCallback!.onMessage = (message) {
      print(
          '${user2.name} receive message from sendMessageScenario ${message.message!.id} ${message.message!.body}');
      if (!completer.isCompleted &&
          message.message!.body == 'I miss you. jub jub.') {
        // completer.complete(true);
      }
    };

    user2.xmppCallback!.onConnectionStatus = (XmppConnectionState state) {
      print('${user2.name} onConnectionStatus ${state.toString()}');
    };

    for (var i = 0; i < nMessage; i++) {
      try {
        if (i == nMessage - 1) {
          user1.sendMessage(message: 'I miss you. jub jub.', user: user2);
        }
        // await Future.delayed(Duration(milliseconds: 200));
        user1.sendMessage(message: i.toString().padLeft(40, '0'), user: user2);

        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 2),
            getUserByIndex(users, keys, userOffset, 3), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 3),
            getUserByIndex(users, keys, userOffset, 4), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 4),
            getUserByIndex(users, keys, userOffset, 5), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 5),
            getUserByIndex(users, keys, userOffset, 6), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 6),
            getUserByIndex(users, keys, userOffset, 7), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 7),
            getUserByIndex(users, keys, userOffset, 8), i.toString());
        performSendMessageTwoUsers(getUserByIndex(users, keys, userOffset, 8),
            getUserByIndex(users, keys, userOffset, 9), i.toString());
      } catch (e) {
        print(e.toString());
      }
    }

    return completer.future;
  }

  void performSendMessageTwoUsers(User userA, User userB, String message) {
    if (userB.xmppCallback!.onMessage == noFunc) {
      userB.xmppCallback!.onMessage = (message) {
        print(
            '${userA.name} receive message from sendMessageScenario ${message.message!.id} ${message.message!.body}');
      };

      userB.xmppCallback!.onConnectionStatus = (XmppConnectionState state) {
        print('${userB.name} onConnectionStatus ${state.toString()}');
      };
    }

    userA.sendMessage(message: message.padLeft(40, '0'), user: userB);
  }

  SendMassivePersonal copyWith({
    UsersConnection? users,
    int? nIteration,
    int? batchSize,
  }) {
    return SendMassivePersonal(
      users: users ?? this.users,
      nIteration: nIteration ?? this.nIteration,
      batchSize: batchSize ?? this.batchSize,
    );
  }

  @override
  String toString() => 'SendMassivePersonal(users: $users)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SendMassivePersonal &&
      other.users == users;
  }

  @override
  int get hashCode => users.hashCode;
}
