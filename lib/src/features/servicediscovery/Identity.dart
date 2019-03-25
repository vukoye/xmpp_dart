import 'package:xmpp/src/elements/XmppElement.dart';

class Identity extends XmppElement {
  String get category { return this.getAttribute('category')?.value;}
  String get type { return this.getAttribute('type')?.value;}
  String get name { return this.getAttribute('name')?.value;}
}