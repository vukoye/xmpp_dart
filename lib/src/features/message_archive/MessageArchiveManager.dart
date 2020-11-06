import 'dart:async';

import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/features/rsm/RsmSetResult.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import '../../Connection.dart';
import '../../data/Jid.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../../elements/forms/FieldElement.dart';

///Implementation of XEP-0313: Message Archive Management
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

  MessageArchiveManager(this._connection) {
    _connection.inStanzasStream.listen(iqListener);
  }

  List<String> _unrespondedIqs =[];

  final StreamController<RsmSetResult> _queryResultStreamController =
  StreamController.broadcast();

  /// Listening for the state of your query
  Stream<RsmSetResult> get queryResultState => _queryResultStreamController.stream;

  /// Querying all messages, returns queryId
  String queryAll() {
    var queryId = AbstractStanza.getRandomId();
    var iqId = AbstractStanza.getRandomId();
    _unrespondedIqs.add(iqId);
    var iqStanza = IqStanza(iqId, IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns('urn:xmpp:mam:2');
    query.setQueryId(queryId);
    iqStanza.addChild(query);
    _connection.writeStanza(iqStanza);
    return queryId;
  }

  /// Querying messages based on date, returns queryId
  String queryByTime({DateTime start, DateTime end, Jid jid}) {
    if (start == null && end == null && jid == null) {
      return queryAll();
    } else {
      var queryId = AbstractStanza.getRandomId();
      var iqId = AbstractStanza.getRandomId();
      _unrespondedIqs.add(iqId);
      var iqStanza = IqStanza(iqId, IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns('urn:xmpp:mam:2');
      query.setQueryId(queryId);
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

  ///Querying messages based on messageId, returns queryId
  ///
  /// This method requires urn:xmpp:mam:2#extended to be supported by the server
  /// In the Set element you can query for maximum number of elements after desired element
  String queryById({String beforeId, String afterId, Jid jid, Set set}) {
    if (beforeId == null && afterId == null && jid == null) {
      return queryAll();
    } else {
      var queryId = AbstractStanza.getRandomId();
      var iqId = AbstractStanza.getRandomId();
      _unrespondedIqs.add(iqId);
      var iqStanza = IqStanza(iqId, IqStanzaType.SET);
      var query = QueryElement();
      query.setXmlns('urn:xmpp:mam:2');
      query.setQueryId(queryId);
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
      return queryId;
    }
  }

  void iqListener(AbstractStanza event) {
    if (event.id != null && event is IqStanza && _unrespondedIqs.contains(event.id)) {
      _unrespondedIqs.remove(event.id);
      //parse Iq and return result
      var finElement = event.getChild('fin');
      if (finElement != null) {
        var complete = finElement
            ?.getAttribute('complete')
            ?.value == 'true';
        var setElement = finElement.getChild('set');
    //     //todo parse this
    // <!-- result messages -->
    // <iq type='result' id='u29303'>
    // <fin xmlns='urn:xmpp:mam:2' complete='true'>
    // <set xmlns='http://jabber.org/protocol/rsm'>
    // <first index='0'>23452-4534-1</first>
    // <last>390-2342-22</last>
    // <count>16</count>
    // </set>
    // </fin>
    // </iq>
        if (setElement != null) {
          var first = setElement.getChild('first')?.textValue;
          var index = setElement.getChild('first')?.textValue;
        }
      }

    }
  }
}

///method for getting instance of MessageArchiveManager
extension MamModuleGetter on Connection {
  MessageArchiveManager getMamModule() {
    return MessageArchiveManager.getInstance(this);
  }
}
