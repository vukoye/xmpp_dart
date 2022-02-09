import 'package:xmpp_stone/src/features/message_archive/MessageArchiveData.dart';

abstract class MessageArchiveListener {
  void onFinish(MessageArchiveResult? iqStanza);
}
