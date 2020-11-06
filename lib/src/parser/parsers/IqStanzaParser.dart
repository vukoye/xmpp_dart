import 'package:xml/src/xml/nodes/element.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/parser/XmppElementParser.dart';

class IqStanzaParser extends XmppElementParser {
  @override
  bool elementValidator(XmlElement xmlElement) => xmlElement.name.local == 'iq';

  @override
  XmppElement parse(XmlElement xmlElement) {
    var id = xmlElement.getAttribute('id');
    return IqStanza(id, _parseIqType(xmlElement));
  }

  IqStanzaType _parseIqType(XmlElement xmlElement) {
    var typeString = xmlElement.getAttribute('type');
    switch (typeString) {
      case 'error':
        return IqStanzaType.ERROR;
      case 'set':
        return IqStanzaType.SET;
      case 'result':
        return IqStanzaType.RESULT;
      case 'get':
        return IqStanzaType.GET;
      case 'invalid':
        return IqStanzaType.INVALID;
      case 'timeout':
        return IqStanzaType.TIMEOUT;
    }
    return IqStanzaType.INVALID;
  }
}
