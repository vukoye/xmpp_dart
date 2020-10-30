import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import '../../Connection.dart';
import '../../data/Jid.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../../elements/forms/FieldElement.dart';

class MessageArchiveManager {
  static const TAG = 'MessageArchiveManager';

  static final Map<Connection, MessageArchiveManager> _instances =
      <Connection, MessageArchiveManager>{};

  static MessageArchiveManager getInstance(Connection connection) {
    var instance = _instances[connection];
    if (instance == null) {
      instance = MessageArchiveManager(connection);
      _instances[connection] = instance;
    }
    return instance;
  }

  final Connection _connection;

  bool get enabled => MAMNegotiator.getInstance(_connection).enabled;

  bool get hasExtended => MAMNegotiator.getInstance(_connection).hasExtended;

  bool get isQueryByDateSupported => MAMNegotiator.getInstance(_connection).isQueryByDateSupported;

  bool get isQueryByIdSupported => MAMNegotiator.getInstance(_connection).isQueryByIdSupported;

  bool get isQueryByJidSupported => MAMNegotiator.getInstance(_connection).isQueryByJidSupported;

  MessageArchiveManager(this._connection);

  void queryAll() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns('urn:xmpp:mam:2');
    query.setQueryId(AbstractStanza.getRandomId());
    iqStanza.addChild(query);
    _connection.writeStanza(iqStanza);
  }

  void queryByTime({DateTime start, DateTime end, Jid jid}) {
    if (start == null && end == null && jid == null) {
      queryAll();
    } else {
      var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns('urn:xmpp:mam:2');
      query.setQueryId(AbstractStanza.getRandomId());
      iqStanza.addChild(query);
      var x = XElement.build();
      x.setType(FormType.SUBMIT);
      query.addChild(x);
      x.addField(FieldElement.build(
          varAttr: 'FORM_TYPE', typeAttr: 'hidden', value: 'urn:xmpp:mam:2'));
      if (start != null) {
        x.addField(
            FieldElement.build(varAttr: 'start', value: start.toIso8601String()));
      }
      if (end != null) {
        x.addField(FieldElement.build(varAttr: 'end', value: end.toIso8601String()));
      }
      if (jid != null) {
        x.addField(FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      _connection.writeStanza(iqStanza);
    }
  }

  void queryById({String beforeId, String afterId, Jid jid}) {
    if (beforeId == null && afterId == null && jid == null) {
      queryAll();
    } else {
      var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns('urn:xmpp:mam:2');
      query.setQueryId(AbstractStanza.getRandomId());
      iqStanza.addChild(query);
      var x = XElement.build();
      x.setType(FormType.SUBMIT);
      query.addChild(x);
      x.addField(FieldElement.build(
          varAttr: 'FORM_TYPE', typeAttr: 'hidden', value: 'urn:xmpp:mam:2'));
      if (beforeId != null) {
        x.addField(FieldElement.build(varAttr: 'beforeId', value: beforeId));
      }
      if (afterId != null) {
        x.addField(FieldElement.build(varAttr: 'afterId', value: afterId));
      }
      if (jid != null) {
        x.addField(FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      _connection.writeStanza(iqStanza);
    }
  }
}

//method for getting module
extension MamModuleGetter on Connection {
  MessageArchiveManager getMamModule() {
    return MessageArchiveManager.getInstance(this);
  }
}
