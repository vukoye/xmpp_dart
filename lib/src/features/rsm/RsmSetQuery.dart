import 'package:xmpp_stone/src/elements/rst/SetElement.dart';

class RsmSetQuery {
  int max;
  String after;
  String before;
}

extension RsmConverter on RsmSetQuery {
  SetElement toSetElement() => SetElement.build(max: max, after: after, before: before);
}