import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class EnvelopeFrom extends XmppElement {
  static String elementName = 'from';
  EnvelopeFrom() {
    name = elementName;
  }

  EnvelopeFrom.build({
    required Jid jid,
  }) {
    name = EnvelopeFrom.elementName;
    addAttribute(XmppAttribute('jid', jid.userAtDomain));
  }
  static XmppElement? parse(parent) {
    return parent.children.firstWhere(
        (child) => (child.name == EnvelopeFrom.elementName),
        orElse: () => null);
  }
}
