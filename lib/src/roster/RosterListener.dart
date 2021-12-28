import 'package:xmpp_stone/src/roster/Buddy.dart';

abstract class RosterListener {
  void onRosterListChanged(List<Buddy> roster);
}
