import 'package:xmpp_stone/src/access_point/manager.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

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
  _context.presenceSend(PresenceShowElement.AWAY, description: 'Working');
  // Read your vcard profile
  _context.vCardRead();
  // Update your vcard profile
  _context.vCardUpdate((vCardToUpdate) {
    vCardToUpdate.bDay = '1992-05-21';
    vCardToUpdate.nickName = 'Sean';
    vCardToUpdate.fullName = 'Promsopheak8';
    return vCardToUpdate;
  });

  _context.vCardFrom(friendAlice);
  // _context.rosterAdd(friendAlice);
  // get roster list
  _context.rosterList();
  // Get presence from alice
  _context.presenceFrom(friendAlice);

  // send text message
  _context.sendMessage('good morning Alice', friendAlice);
}

void onManagerForAliceReady(XMPPClientManager _context) {
  var friendSean = 'boo@localhost';
  _context.presenceSend(PresenceShowElement.CHAT, description: 'Working');
  // Read your vcard profile
  _context.vCardRead();
  // Update Alice profile
  _context.vCardUpdate((vCardToUpdate) {
    vCardToUpdate.bDay = '1993-02-21';
    vCardToUpdate.nickName = 'Alice';
    vCardToUpdate.fullName = 'Alice77';
    return vCardToUpdate;
  });

  _context.vCardFrom(friendSean);
  // _context.rosterAdd(friendSean);
  // get roster list
  _context.rosterList();
  // Get presence from alice
  _context.presenceFrom(friendSean);
}
