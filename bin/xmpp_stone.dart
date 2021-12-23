import 'package:xmpp_stone/src/access_point/manager.dart';

final String TAG = 'example';
// Sean side - 0
final String C_SENDER = 'boo@localhost';
final String C_RECEIVER = 'alice@localhost';
final String C_RECEIVER_BOB = 'bob@localhost';
final String HOST = 'localhost';

void main(List<String> arguments) {
  var seanClient = XMPPClientManager('boo@localhost', 'qwerty',
      onReady: onManagerForSeanReady, host: HOST, onLog: onLog);
  seanClient.createSession();
  var aliceClient = XMPPClientManager('alice@localhost', 'qwerty',
      onReady: onManagerForAliceReady, host: HOST, onLog: onLog);
  aliceClient.createSession();
}

void onLog(String time, String message) {}

void onManagerForSeanReady(XMPPClientManager _context) {
  _context.listens();
  var friendAlice = 'alice@localhost';
  _context.presenceSend();
  // Read your vcard profile
  _context.vCardRead();
  // Update your vcard profile
  _context.vCardUpdate((vCardToUpdate) {
    vCardToUpdate.bDay = '1992-05-21';
    vCardToUpdate.nickName = 'Sean';
    vCardToUpdate.fullName = 'Promsopheak8';
    return vCardToUpdate;
  });

  // Query the service information
  // _context.mucDiscover('muc.localhost');
  // _context.mucDiscover('mudddc.localhost'); // incorrect service discover
  // query card from buddy
  // _context.vCardFrom(C_RECEIVER);
  // _context.rosterAdd(C_RECEIVER);

  _context.vCardFrom(friendAlice);
  // _context.rosterAdd(friendAlice);
  // get roster list
  _context.rosterList();
  // Get presence from alice
  _context.presenceFrom(friendAlice);

  // send text message
  _context.sendMessage('good morning Alice', friendAlice,
      messageId: DateTime.now().millisecondsSinceEpoch.toString());
}

void onManagerForAliceReady(XMPPClientManager _context) {
  var friendSean = 'boo@localhost';
  _context.presenceSend();
  // Read your vcard profile
  _context.vCardRead();
  // Update Alice profile
  _context.vCardUpdate((vCardToUpdate) {
    vCardToUpdate.bDay = '1993-02-21';
    vCardToUpdate.nickName = 'Alice';
    vCardToUpdate.fullName = 'Alice77';
    return vCardToUpdate;
  });
  // Query the service information
  // _context.mucDiscover('muc.localhost');
  // _context.mucDiscover('mudddc.localhost'); // incorrect service discover
  // query card from buddy
  // _context.vCardFrom(C_RECEIVER);
  // _context.rosterAdd(C_RECEIVER);

  _context.vCardFrom(friendSean);
  // _context.rosterAdd(friendSean);
  // get roster list
  _context.rosterList();
  // Get presence from alice
  _context.presenceFrom(friendSean);
}
