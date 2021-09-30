import 'manager.dart';

final String TAG = 'example';
// Sean side - 0
final String C_SENDER = 'sean@localhost';
final String C_RECEIVER = 'alice@localhost';
final String C_RECEIVER_BOB = 'bob@localhost';

// Alice side - 1
// final String C_SENDER = 'alice@localhost';
// final String C_RECEIVER = 'sean@localhost';

void main(List<String> arguments) {
  var client = XMPPClientManager(C_SENDER, 'qwerty', onManagerReady);
  client.createSession();
  client.listens();
}

void onManagerReady(XMPPClientManager _context) {
  // Read your vcard profile
  _context.vCardRead();
  // Update your vcard profile
  // _context.vCardUpdate((vCardToUpdate) {
  //   vCardToUpdate.bDay = '1992-05-21';
  //   vCardToUpdate.nickName = 'Sean';
  //   vCardToUpdate.fullName = 'Promsopheak8';
  //   return vCardToUpdate;
  // });

  // _context.vCardUpdate((vCardToUpdate) {
  //   vCardToUpdate.bDay = '1993-02-21';
  //   vCardToUpdate.nickName = 'Alice';
  //   vCardToUpdate.fullName = 'Alice77';
  //   return vCardToUpdate;
  // });
  // Query the service information
  // _context.mucDiscover('muc.localhost');
  // _context.mucDiscover('mudddc.localhost'); // incorrect service discover
  // query card from buddy
  // _context.vCardFrom(C_RECEIVER);
  // _context.rosterAdd(C_RECEIVER);

  _context.vCardFrom(C_RECEIVER_BOB);
  _context.rosterAdd(C_RECEIVER_BOB);
  // get roster list
  _context.rosterList();

}
