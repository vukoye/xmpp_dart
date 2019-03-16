import 'package:meta/meta.dart';
import 'package:xmpp/src/Connection.dart';
import 'package:xmpp/src/ConnectionStateChangedListener.dart';
import 'package:xmpp/src/StanzaListener.dart';
import 'package:xmpp/src/data/Jid.dart';
import 'package:xmpp/src/elements/XmppAttribute.dart';
import 'package:xmpp/src/elements/XmppElement.dart';
import 'package:xmpp/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp/src/roster/Buddy.dart';
import 'package:xmpp/src/roster/RosterListener.dart';

class RosterManager implements ConnectionStateChangedListener, StanzaProcessor {


  static Map<Connection, RosterManager> instances = Map<Connection, RosterManager>();

  Map<String, IqStanza> _myUnrespondedIqStanzas = Map<String, IqStanza>();

  List<RosterListener> _rosterListeners = List<RosterListener>();

  Map<Jid, Buddy> _rosterMap = Map<Jid, Buddy>();

  static getInstance(Connection connection) {
    RosterManager manager = instances[connection];
    if (manager == null) {
      manager = RosterManager(connection);
      instances[connection] = manager;
      connection.addStanzaListener(manager);
    }

    return manager;
  }

  Connection _connection;

  void _getRosters() {
    IqStanza iqStanza = IqStanza(AbstractStanza.getRandomId(),  IqStanzaType.GET);
    XmppElement element = XmppElement();
    element.name = 'query';
    element.addAttribute(new XmppAttribute('xmlns', 'jabber:iq:roster'));
    iqStanza.addChild(element);
    _myUnrespondedIqStanzas[iqStanza.id] = iqStanza;
    _connection.writeStanza(iqStanza);
  }

  @override
  void onConnectionStateChanged(XmppConnectionState state) {
    if (state == XmppConnectionState.SessionInitialized) {
      //_getRosters();
      _sendInitialPresence();
    }
  }

  void _sendInitialPresence() {
    _connection.write("<presence/>");
  }

  RosterManager(Connection connection) {
    _connection = connection;
    connection.addConnectionStateChangedListener(this);
  }

  @override
  @protected
  processStanza(AbstractStanza stanza) {
    if (stanza is IqStanza) {
      if (_myUnrespondedIqStanzas[stanza.id] != null && stanza.type == IqStanzaType.RESULT) {
        XmppElement xmppElement = stanza.getChild('query');
        if (xmppElement != null && xmppElement.getNameSpace() == 'jabber:iq:roster') {
          _rosterMap.clear();
          xmppElement.children.forEach((child){
            if (child.name == 'item') {
              Jid jid = Jid.fromFullJid(child.getAttribute('jid').value);
              Buddy buddy = Buddy(jid);
              _rosterMap[jid] = buddy;

            }
          });
          fireOnRosterListChanged();
        }
      }
    }
  }

  void fireOnRosterListChanged() {
    List<Buddy> rosterList = _rosterMap.values.toList();
    _rosterListeners.forEach((listener) => listener.onRosterListChanged(rosterList));
    print("RosterListChanged: ${rosterList}");
  }

  void addRosterListener(RosterListener listener) {
    _rosterListeners.add(listener);
  }

  void removeRosterListener(RosterListener listener) {
    _rosterListeners.remove(listener);
  }
}