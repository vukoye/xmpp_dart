import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/features/message_archive/MessageArchiveData.dart';
import 'package:xmpp_stone/src/features/message_archive/MessageArchiveListener.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import 'package:xmpp_stone/src/logger/Log.dart';
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

  MessageArchiveListener? listener;

  final Connection _connection;

  bool get enabled => MAMNegotiator.getInstance(_connection).enabled;

  bool? get hasExtended => MAMNegotiator.getInstance(_connection).hasExtended;

  bool get isQueryByDateSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByDateSupported;

  bool get isQueryByIdSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByIdSupported;

  bool get isQueryByJidSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByJidSupported;

  MessageArchiveManager(this._connection) {
    _connection.inStanzasStream.listen(_processStanza);
  }

  void queryAll() async {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns('urn:xmpp:mam:2');
    query.setQueryId(AbstractStanza.getRandomId());
    iqStanza.addChild(query);
    await _connection.writeStanzaWithQueue(iqStanza);
  }

  void queryByTime(
      {DateTime? start,
      DateTime? end,
      Jid? jid,
      bool includeGroup = false,
      String? id}) async {
    if (start == null && end == null && jid == null) {
      queryAll();
    } else {
      var iqStanza =
          IqStanza(id ?? AbstractStanza.getRandomId(), IqStanzaType.SET);
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
        x.addField(FieldElement.build(
            varAttr: 'start', value: start.toUtc().toIso8601String()));
      }
      if (end != null) {
        x.addField(FieldElement.build(
            varAttr: 'end', value: end.toUtc().toIso8601String()));
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      if (includeGroup) {
        x.addField(
            FieldElement.build(varAttr: 'include-groupchat', value: 'true'));
      }
      await _connection.writeStanzaWithQueue(iqStanza);
    }
  }

  void queryById(
      {String? beforeId,
      String? afterId,
      Jid? jid,
      String? id,
      bool includeGroup = false}) async {
    if (beforeId == null && afterId == null && jid == null) {
      queryAll();
    } else {
      var iqStanza =
          IqStanza(id ?? AbstractStanza.getRandomId(), IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns('urn:xmpp:mam:2');
      query.setQueryId(AbstractStanza.getRandomId());
      iqStanza.addChild(query);
      var x = XElement.build();
      x.setType(FormType.SUBMIT);
      query.addChild(x);
      x.addField(FieldElement.build(
          varAttr: 'FORM_TYPE', typeAttr: 'hidden', value: 'urn:xmpp:mam:2'));

      if (beforeId != null || afterId != null) {
        final setElement = XmppElement();
        setElement.name = 'set';
        setElement.addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/rsm'));

        if (beforeId != null) {
          final beforeElement = XmppElement();
          beforeElement.name = 'before';
          beforeElement.textValue = beforeId;
          setElement.addChild(beforeElement);
          x.addField(FieldElement.build(varAttr: 'before-id', value: beforeId));
        }
        if (afterId != null) {
          final afterElement = XmppElement();
          afterElement.name = 'after';
          afterElement.textValue = afterId;
          setElement.addChild(afterElement);
          x.addField(FieldElement.build(varAttr: 'after-id', value: afterId));
        }
        // TODO: add max
        query.addChild(setElement);
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      if (includeGroup) {
        x.addField(
            FieldElement.build(varAttr: 'include-groupchat', value: 'true'));
      }
      await _connection.writeStanzaWithQueue(iqStanza);
    }
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      if (stanza.type == IqStanzaType.RESULT) {
        var finMam = stanza.getChild('fin');
        if (finMam != null &&
            finMam.getAttribute('xmlns')!.value == 'urn:xmpp:mam:2') {
          Log.d(TAG, 'Finished querying result');

          if (listener != null) {
            listener!.onFinish(MessageArchiveResult.parseFromXml(stanza));
          }
        }
      } else if (stanza.type == IqStanzaType.ERROR) {
        //todo handle error cases
      }
    }
  }

  void listen(MessageArchiveListener _listener) {
    if (listener != null) {
      listener = null;
    }
    listener = _listener;
  }
}

//method for getting module
extension MamModuleGetter on Connection {
  MessageArchiveManager getMamModule() {
    return MessageArchiveManager.getInstance(this);
  }
}
