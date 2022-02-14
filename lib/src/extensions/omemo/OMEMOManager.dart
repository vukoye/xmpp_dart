import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOManagerApi.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';
import 'package:xmpp_stone/src/response/response.dart';

class OMEMOManager extends OMEMOManagerApi {
  final Connection _connection;

  static final Map<Connection, OMEMOManager> _instances =
      <Connection, OMEMOManager>{};

  static final ResponseHandler<IqStanza> responseHandler =
      ResponseHandler<IqStanza>();

  OMEMOManager(this._connection) {
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

  void _processStanza(AbstractStanza? stanza) {
    if (stanza is IqStanza) {
      responseHandler.test(stanza.id!, (res) {
        if (res.item3 == OMEMOGetDevicesResponse) {
          // handle response
          final response = OMEMOGetDevicesResponse.parse(stanza);
          res.item2.complete(response);
        }
      });
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
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    _connection.writeStanza(requestStanza);
    return responseHandler.set<OMEMOGetDevicesResponse>(
        requestStanza.id!, requestStanza);
  }

  @override
  Future<OMEMOPublishDeviceResponse> publishDevice(
      OMEMOPublishDeviceParams params) {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    _connection.writeStanza(requestStanza);
    return responseHandler.set<OMEMOPublishDeviceResponse>(
        requestStanza.id!, requestStanza);
  }
}
