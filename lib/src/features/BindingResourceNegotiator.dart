import 'dart:async';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/data/Jid.dart';
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/features/Negotiator.dart';

class BindingResourceConnectionNegotiator extends ConnectionNegotiator {
  Connection _connection;
  StreamSubscription<AbstractStanza> subscription;
  static const String BIND_NAME = 'bind';
  static const String BIND_ATTRIBUTE = 'urn:ietf:params:xml:ns:xmpp-bind';

  BindingResourceConnectionNegotiator(Connection connection) {
    _connection = connection;
    priorityLevel = 100;
  }
  @override
  bool match(Nonza request) {
    return request.name == BIND_NAME;
  }

  @override
  void negotiate(Nonza nonza) {
    if (nonza.name == BIND_NAME) {
      state = NegotiatorState.NEGOTIATING;
      subscription = _connection.inStanzasStream.listen(parseStanza);
      sendBindRequestStanza(_connection.account.resource);
    }
  }

  void parseStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      var element = stanza.getChild(BIND_NAME);
      var jidValue = element?.getChild('jid')?.textValue;
      if (jidValue != null) {
        var jid = Jid.fromFullJid(jidValue);
        _connection.fullJidRetrieved(jid);
        state = NegotiatorState.DONE;
        subscription.cancel();
      }
    }
  }

  void sendBindRequestStanza(String resource) {
    var stanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var bindElement = XmppElement();
    bindElement.name = BIND_NAME;
    var resourceElement = XmppElement();
    resourceElement.name = 'resource';
    resourceElement.textValue = resource;
    bindElement.addChild(resourceElement);
    var attribute = XmppAttribute('xmlns', BIND_ATTRIBUTE);
    bindElement.addAttribute(attribute);
    stanza.addChild(bindElement);
    _connection.writeStanza(stanza);
  }
}
