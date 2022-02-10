import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOManagerApi.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';
import 'package:xmpp_stone/src/extensions/ping/PingListener.dart';

class OMEMOManager extends OMEMOManagerApi {
  final Connection _connection;

  PingListener? listener;

  static final Map<Connection, OMEMOManager> _instances =
      <Connection, OMEMOManager>{};

  OMEMOManager(this._connection) {
    _connection.connectionStateStream.listen(_connectionStateProcessor);
    _connection.inStanzasStream.listen(_processStanza);
  }

  static OMEMOManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = OMEMOManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  void _connectionStateProcessor(XmppConnectionState event) {
    // connection state processor.
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      if (stanza.type == IqStanzaType.GET) {
        var ping = stanza.getChild('ping');
        if (ping != null) {
          var iqStanza = IqStanza(stanza.id, IqStanzaType.RESULT);
          iqStanza.fromJid = _connection.fullJid;
          iqStanza.toJid = stanza.fromJid;
          _connection.writeStanza(iqStanza);

          if (listener != null) {
            listener!.onPing(stanza);
          }
        }
      } else if (stanza.type == IqStanzaType.ERROR) {
        //todo handle error cases
      }
    }
  }

  @override
  Future<OMEMOPublishBundleResponse> publishBundle(
      OMEMOPublishBundleParams params) {
    throw UnimplementedError();
  }

  @override
  Future<OMEMOEnvelopeEncryptionResponse> envelopeEncryptionContent(
      OMEMOEnvelopeEncryptionParams params) {
    throw UnimplementedError();
  }

  @override
  Future<OMEMOEnvelopePlainTextResponse> envelopePlainContent(
      OMEMOEnvelopePlainTextParams params) {
    throw UnimplementedError();
  }

  @override
  Future<OMEMOGetBundleResponse> fetchBundle(OMEMOGetBundleParams params) {
    throw UnimplementedError();
  }

  @override
  Future<OMEMOGetDevicesResponse> fetchDevices(OMEMOGetDevicesParams params) {
    throw UnimplementedError();
  }
}
