//part of xmpp_dart;
//
//class IqStanzaHandler {
//  Connection _connection;
//
//  Map<String, IqStanza> unRepliedStanzas = new Map();
//
//  void processIqStanza(xml.XmlElement element) {
//    if (element.name.local != 'iq') return;
//    if (element.getAttributeNode('type').value == 'result') {
//      if (element.findAllElements('bind') != null) {
//        element.findAllElements('jid').forEach((jidElement) {
//          var jid = Jid.fromFullJid(jidElement.text);
//          _connection.fullJid = jid;
//        });
//      }
//      var stanza = unRepliedStanzas[element.getAttribute('id')];
//
//      if (stanza != null) unRepliedStanzas.remove(stanza);
//
//    }
//  }
//
//  String getBindRequest() {
//    var attribute = xml.XmlAttribute(
//        xml.XmlName('xmlns'), 'urn:ietf:params:xml:ns:xmpp-bind');
//    var element = xml.XmlElement(xml.XmlName('bind'), [attribute]);
//    IqStanza iqStanza = IqStanza(getRandomId(), IqStanzaType.SET, element);
//    return iqStanza.buildXml();
//  }
//
//  IqStanzaHandler(Connection connection) {
//    _connection = connection;
//  }
//
//  String getSessionRequest(String to) {
//    var attribute = xml.XmlAttribute(xml.XmlName('xmlns'), 'urn:ietf:params:xml:ns:xmpp-session');
//    var attributeTo = xml.XmlAttribute(xml.XmlName('xmlns'), 'urn:ietf:params:xml:ns:xmpp-session');
//    var element = xml.XmlElement(xml.XmlName('session'), [attribute]);
//    IqStanza iqStanza = IqStanza(getRandomId(), IqStanzaType.SET, element);
//    iqStanza.toJid = Jid("", to, "");
//    unRepliedStanzas[iqStanza.id] = iqStanza;
//    return iqStanza.buildXml();
//  }
//
//}
