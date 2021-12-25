import 'dart:collection';

import 'package:xmpp_stone_obelisk/src/elements/stanzas/AbstractStanza.dart';

class StreamState {
  String? id;
  bool streamManagementEnabled = false;
  bool streamResumeEnabled = false;
  int lastSentStanza = 0;
  int lastReceivedStanza = 0;
  Queue nonConfirmedSentStanzas = Queue<AbstractStanza>();

  bool tryingToResume = false;
  bool isResumeAvailable() => id != null && streamResumeEnabled;
}
