import 'models/xmpp_communication_callback.dart';
import 'user.dart';

class UsersConnection {
  Map<String,User> users;
  XmppCommunicationCallback xmppCallback;

  UsersConnection({required this.users,required this.xmppCallback});
}