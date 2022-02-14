import 'dart:async';

import 'models/xmpp_communication_callback.dart';
import 'user.dart';
import 'users_connection.dart';

final String TAG = 'example';

void main(List<String> arguments) async {
  
  final UsersConnection users = await initUser();
  await sendMessageScenario(users);
  await createGroupScenario(users);
  await removeMembersInGroupScenario(users);
}

// user A send message to user B
Future<void> sendMessageScenario(UsersConnection users) async {
  var completer = Completer<void>();
  users.users['cheata']?.xmppCallback.onMessage = (message){
    print('cheata receive message from sendMessageScenario ${message.message!.body}');
    if(!completer.isCompleted && message.message!.body == 'I miss you. jub jub.'){
      completer.complete();
    }
  };
  users.users['kevin']?.xmppCallback.onMessage = (message){
    print('kevin receive message from sendMessageScenario ${message.message!.body}');
    // if(!completer.isCompleted){
    //   completer.complete();
    // }
  };
  users.users['kevin']?.sendMessage(message: 'I miss you. jub jub.', user: users.users['cheata']!);
  return completer.future;
}

// create group with 2 user
Future<void> createGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];
  usersJid.add(users.users['cheata']?.jid ?? '');
  await users.users['kevin']?.createGroup(roomName: 'test2', usersJid: usersJid);
  final members = await users.users['kevin']?.getMembers(roomName: 'test1');
  final admins = await users.users['kevin']?.getAdmins(roomName: 'test1');
  final owners = await users.users['kevin']?.getOwners(roomName: 'test1');
  return Future.value();
}

// remove a member from group
Future<void> removeMembersInGroupScenario(UsersConnection users) async {
  List<String> usersJid = [];
  usersJid.add(users.users['cheata']?.jid ?? '');
  await users.users['kevin']?.removeMembersInGroup(roomName: 'test1', usersJid: usersJid);
  final members = await users.users['kevin']?.getMembers(roomName: 'test1');
  final admins = await users.users['kevin']?.getAdmins(roomName: 'test1');
  final owners = await users.users['kevin']?.getOwners(roomName: 'test1');
  return Future.value();
}


Future<UsersConnection> initUser() async {
  // final XMPPClientManager xmppClientManager;
  var completer = Completer<UsersConnection>();
  UsersConnection usersConnection = UsersConnection(users: {}, xmppCallback: XmppCommunicationCallback());
  int countUserConnected = 0; 
  var host = 'localhost';
  var kevinAtDomain = '1644-592557-948158-86170b0456c872be@${host}';
  var resource = '';
  var password = 'password';
  
  var kevinJid = '${kevinAtDomain}$resource';
  var kevinUser = User('kevin', kevinJid, password, XmppCommunicationCallback());
  kevinUser.connect((){
    print("kevin ready");
    if(++countUserConnected == 2){
      completer.complete(usersConnection);
    }
  });

  var cheataAtDomain = '1644-594667-940460-3d8c9a003c4abe60@${host}';
  var cheataJid = '${cheataAtDomain}$resource';
  var cheataUser = User('cheata', cheataJid, password,  XmppCommunicationCallback());
  cheataUser.connect((){
    print("cheata ready");
    if(++countUserConnected == 2){
      completer.complete(usersConnection);
    }
  });

  usersConnection.users['kevin'] = kevinUser;
  usersConnection.users['cheata'] = cheataUser;
  return completer.future;
}