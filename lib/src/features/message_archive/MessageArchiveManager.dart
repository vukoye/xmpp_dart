import 'dart:async';

import 'package:xmpp_stone/src/elements/forms/QueryElement.dart';
import 'package:xmpp_stone/src/elements/forms/XElement.dart';
import 'package:xmpp_stone/src/features/servicediscovery/MAMNegotiator.dart';
import 'package:xmpp_stone/xmpp_stone.dart';
import '../../elements/forms/FieldElement.dart';

class MessageArchiveManager {
  static const TAG = 'MessageArchiveManager';

  static final Map<Connection, MessageArchiveManager> _instances = {};

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

  bool? get hasExtended => MAMNegotiator.getInstance(_connection).hasExtended;

  bool get isQueryByDateSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByDateSupported;

  bool get isQueryByIdSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByIdSupported;

  bool get isQueryByJidSupported =>
      MAMNegotiator.getInstance(_connection).isQueryByJidSupported;

  MessageArchiveManager(this._connection);

  Future<QueryResult> _queryMessages(
      IqStanza iqStanza, QueryElement query) async {
    final messages = <Message>[];
    final completer = Completer<QueryResult>();

    late StreamSubscription dataSubscription;
    dataSubscription = _connection.inStanzasStream
        .where((event) => event is MessageStanza)
        .where((event) =>
            event?.children.any((element) =>
                element.name == 'result' &&
                element.getAttribute('queryid')?.value == query.queryId) ==
            true)
        .map((event) => Message.fromStanza(event as MessageStanza))
        .listen(
      (event) {
        messages.addAll(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        print(error);
        print(stackTrace);
      },
    );

    late StreamSubscription resultSubscription;
    resultSubscription = _connection.inStanzasStream
        .where((event) =>
            event is IqStanza &&
            event.type == IqStanzaType.RESULT &&
            event.id == iqStanza.id)
        .listen(
      (event) {
        dataSubscription.cancel();
        resultSubscription.cancel();

        try {
          final iqStanza = event as IqStanza;
          final finElement = iqStanza.getChild('fin')!;
          final setElement = finElement.getChild('set')!;

          completer.complete(QueryResult(
            finElement.getAttribute('complete')!.value == 'true',
            int.parse(setElement.getChild('count')!.textValue!),
            setElement.getChild('first')?.textValue,
            setElement.getChild('last')?.textValue,
            messages,
          ));
        } catch (e) {
          completer.completeError(
              Exception('Unable to parse result: ${event?.buildXmlString()}'));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
      },
    );

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<QueryResult> queryAll() {
    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET);
    var query = QueryElement();
    query.setXmlns('urn:xmpp:mam:2');
    query.setQueryId(AbstractStanza.getRandomId());
    iqStanza.addChild(query);
    return _queryMessages(iqStanza, query);
  }

  Future<QueryResult> queryByTime(
      {DateTime? start,
      DateTime? end,
      Jid? jid,
      int? max,
      bool flipPage = false}) {
    if (start == null && end == null && jid == null) {
      return queryAll();
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
        final iso8601 = start.toUtc().toIso8601String();
        final startStr = iso8601.substring(0, iso8601.length - 4) + 'Z';
        x.addField(FieldElement.build(varAttr: 'start', value: startStr));
      }
      if (end != null) {
        final iso8601 = end.toUtc().toIso8601String();
        final endStr = iso8601.substring(0, iso8601.length - 4) + 'Z';
        x.addField(FieldElement.build(varAttr: 'end', value: endStr));
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      if (max != null) {
        query.addChild(XmppElement('set')
          ..addAttribute(
              XmppAttribute('xmlns', 'http://jabber.org/protocol/rsm'))
          ..addChild(XmppElement('max')..textValue = max.toString()));
      }
      if (flipPage) {
        query.addChild(
          XmppElement('flip-page'),
        );
      }
      return _queryMessages(iqStanza, query);
    }
  }

  Future<QueryResult> queryById({String? beforeId, String? afterId, Jid? jid}) {
    if (beforeId == null && afterId == null && jid == null) {
      return queryAll();
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
        x.addField(FieldElement.build(varAttr: 'before-id', value: beforeId));
      }
      if (afterId != null) {
        x.addField(FieldElement.build(varAttr: 'after-id', value: afterId));
      }
      if (jid != null) {
        x.addField(
            FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
      }
      return _queryMessages(iqStanza, query);
    }
  }

  Future<QueryResult> query(
      {Jid? jid,
      int? max,
      String? after,
      String? before,
      bool flipPage = false}) {
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
    if (jid != null) {
      x.addField(FieldElement.build(varAttr: 'with', value: jid.userAtDomain));
    }
    if (max != null || after != null) {
      final set = XmppElement('set')
        ..addAttribute(
            XmppAttribute('xmlns', 'http://jabber.org/protocol/rsm'));
      if (max != null) {
        set.addChild(XmppElement('max')..textValue = max.toString());
      }
      if (after != null) {
        set.addChild(XmppElement('after')..textValue = after);
      }
      if (before != null) {
        set.addChild(XmppElement('before')..textValue = before);
      }
      query.addChild(set);
    }
    if (flipPage) {
      query.addChild(
        XmppElement('flip-page'),
      );
    }
    return _queryMessages(iqStanza, query);
  }
}

//method for getting module
extension MamModuleGetter on Connection {
  MessageArchiveManager getMamModule() {
    return MessageArchiveManager.getInstance(this);
  }
}

class QueryResult {
  final bool complete;
  final int count;
  final String? first;
  final String? last;
  final List<Message> messages;

  QueryResult(this.complete, this.count, this.first, this.last, this.messages);

  @override
  String toString() {
    return 'QueryResult(complete: $complete, count: $count, first: $first, last: $last, messages: $messages)';
  }
}
