import 'manager.dart';

final String TAG = 'example';
// Sean side - 0
final String C_RECEIVER = 'alice@localhost';
final String C_SENDER = 'sean@localhost';

// Alice side - 1
// final String C_SENDER = 'alice@localhost';
// final String C_RECEIVER = 'sean@localhost';

void main(List<String> arguments) {
  var client = XMPPClientManager(C_SENDER, 'qwerty', onManagerReady);
  client.createSession();
  client.readSessionLogs();
}

void onManagerReady(XMPPClientManager _context) {
  // Read your vcard profile
  _context.vCardRead();
  // Update your vcard profile
  _context.vCardUpdate((vCardToUpdate) {
    vCardToUpdate.bDay = '1992-05-21';
    vCardToUpdate.nickName = 'Sean';
    vCardToUpdate.fullName = 'Promsopheak';
    return vCardToUpdate;
  });

}
