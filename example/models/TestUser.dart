import '../user.dart';
import 'xmpp_communication_callback.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class TestUser {
 
  TestUser();

  Map<String,User> getTestUser(){
    final host = 'staging.xmpp.hiapp-chat.com';
    Map<String,User> users = {
      '62612223931': User(
        name: 'kevin1',
        password: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjEsInJvbGUiOiJVU0VSIiwidXNlciI6IjYyNjEyMjIzOTMxIiwiaWF0IjoxNjQ3NTcwNTE2LCJleHAiOjMxNzE5MjAxMjkxNn0.m7zBlAf9j-xdPPy1Qugq_cEqC596kmnf-m4DdCWRUSA',
        jid: '62612223931@${host}/kevin1',
        phoneNumber:'62612223931',
        xmppCallback: XmppCommunicationCallback()),
      '62612223932': User(
        name: 'kevin2',
        password: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjUsInJvbGUiOiJVU0VSIiwidXNlciI6IjYyNjEyMjIzOTMyIiwiaWF0IjoxNjQ3NTcyMTIwLCJleHAiOjMxNzE5MjAxNDUyMH0.x2pVGbt5Q9z3ONeUNsz6d3Yu0Gr6Qiru2UWzxQKxkGE',
        jid: '62612223932@${host}/kevin2',
        phoneNumber: '62612223932',
        xmppCallback: XmppCommunicationCallback()),
    };

    return users;
  }
  
  User generateUser(int i){
    final host = 'staging.xmpp.hiapp-chat.com';
    final randomUserPhoneNumber = 10000000 + i ;
    final jwt = JWT({
      'id': 123,
      'role': 'user',
      'user': '62${randomUserPhoneNumber}',
    });

    final token = jwt.sign(SecretKey('hiapp-chat'), expiresIn: Duration(days: 10) , algorithm: JWTAlgorithm.HS256);

    final user = User(
        name: randomUserPhoneNumber.toString(),
        password: token,
        jid: '62${randomUserPhoneNumber}@${host}/${i}',
        phoneNumber: randomUserPhoneNumber.toString(),
        xmppCallback: XmppCommunicationCallback());

    return user;
  }

  Map<String,User> generateUsers(int nUser){
    
    Map<String,User> users = Map();

    for (var i = 0; i < nUser; i++) {
      final user = generateUser(i);
      users[user.phoneNumber] = user;
    }

    return users;
  }

}