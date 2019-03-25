import 'package:xmppstone/src/elements/XmppElement.dart';

class Feature extends XmppElement {
  String get xmppVar { return this.getAttribute('var')?.value;}
}