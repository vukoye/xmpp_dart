import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/response/base_response.dart';
import 'package:xmpp_stone/src/response/response.dart';

class ChatMarkerResposne extends BaseResponse {}

class ChatMarkerReadResposne extends BaseResponse {}

class ChatMarkerManager {
  final Connection _connection;

  static final Map<Connection, ChatMarkerManager> _instances =
      <Connection, ChatMarkerManager>{};

  static final ResponseHandler<IqStanza> responseHandler =
      ResponseHandler<IqStanza>();

  ChatMarkerManager(this._connection) {
    // Listen only having stanza and id existed
    // iq, or presence or message
    // server will response some message thru stream

    _connection.inStanzasStream
        .where((AbstractStanza? stanza) =>
            stanza != null && responseHandler.keys().contains(stanza.id ?? ""))
        .listen(_processStanza);
  }

  static ChatMarkerManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = ChatMarkerManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      responseHandler.test(stanza.id!, (res) {
        late BaseResponse response;
        switch (res.item3) {
          case ChatMarkerResposne:
            response = ChatMarkerResposne();
            break;
          case ChatMarkerReadResposne:
            response = ChatMarkerReadResposne();

            break;
        }
        // complete the future
        res.item2.complete(response);
      });
    }
  }

  Future<ChatMarkerResposne> sendMarker(dynamic params) {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    // <message id="123" from=""><chatMarker/></message>

    _connection.writeStanza(requestStanza);

    return responseHandler.set<ChatMarkerResposne>(
        // 123
        requestStanza.id!,
        requestStanza);
  }

  Future<ChatMarkerReadResposne> sendReadMarker(dynamic params) {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    // <message id="123" from=""><chatMarker/></message>

    _connection.writeStanza(requestStanza);

    return responseHandler.set<ChatMarkerReadResposne>(
        // 123
        requestStanza.id!,
        requestStanza);
  }
}
