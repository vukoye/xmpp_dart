
import 'package:xmppstone/src/roster/Buddy.dart';

abstract class RosterListener {
  void onRosterListChanged(List<Buddy> roster);
}