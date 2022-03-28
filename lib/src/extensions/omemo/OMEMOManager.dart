import 'package:xml/xml.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/elements/stanzas/IqStanza.dart';
import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOManagerApi.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';
import 'package:xmpp_stone/src/response/Response.dart';

class OMEMOManager extends OMEMOManagerApi {
  final Connection _connection;

  static final Map<Connection, OMEMOManager> _instances =
      <Connection, OMEMOManager>{};

  static final ResponseHandler<IqStanza> responseHandler =
      ResponseHandler<IqStanza>();

  OMEMOManager(this._connection) {
    // Listen only having stanza and id existed
    _connection.inStanzasStream
        .where((AbstractStanza? stanza) =>
            stanza != null && responseHandler.keys().contains(stanza.id ?? ""))
        .listen(_processStanza);
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
        late BaseResponse response;
        switch (res.item3) {
          case OMEMOGetDevicesResponse:
            response = OMEMOGetDevicesResponse.parse(stanza);
            break;
          case OMEMOPublishDeviceResponse:
            response = OMEMOPublishDeviceResponse.parse(stanza);
            break;
          case OMEMOPublishBundleResponse:
            response = OMEMOPublishBundleResponse.parse(stanza);
            break;
          case OMEMOGetBundleResponse:
            response = OMEMOGetBundleResponse.parse(stanza);
            break;
        }
        res.item2.complete(response);
      });
    }
  }

  @override
  Future<OMEMOPublishBundleResponse> publishBundle(
      OMEMOPublishBundleParams params) async {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    await _connection.writeStanzaWithQueue(requestStanza);
    return responseHandler.set<OMEMOPublishBundleResponse>(
        requestStanza.id!, requestStanza,
        description: 'Publish user OMEMO bundle');
  }

  @override
  Future<OMEMOEnvelopeEncryptionResponse> envelopeEncryptionContent(
      OMEMOEnvelopeEncryptionParams params) {
    final encryptEnvelope = params.buildRequest(from: _connection.fullJid);
    return Future.value(OMEMOEnvelopeEncryptionResponse.parse(encryptEnvelope));
  }

  @override
  Future<OMEMOEnvelopePlainTextResponse> envelopePlainContent(
      OMEMOEnvelopePlainTextParams params) {
    final envelopeElement = params.buildRequest(from: _connection.fullJid);
    return Future.value(
        OMEMOEnvelopePlainTextResponse.parse(envelopeElement.buildXmlString()));
  }

  @override
  Future<OMEMOEnvelopePlainTextParseResponse> parseEnvelopePlainContent(
      OMEMOEnvelopeParsePlainTextParams params) {
    final xmlDoc = XmlDocument.parse('<message>${params.elementXml}</message>');
    final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
    return Future.value(OMEMOEnvelopePlainTextParseResponse.parse(stanza));
  }

  @override
  Future<OMEMOGetBundleResponse> fetchBundle(
      OMEMOGetBundleParams params) async {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    await _connection.writeStanzaWithQueue(requestStanza);
    return responseHandler.set<OMEMOGetBundleResponse>(
        requestStanza.id!, requestStanza,
        description: 'Fetching user OMEMO bundle');
  }

  @override
  Future<OMEMOGetDevicesResponse> fetchDevices(
      OMEMOGetDevicesParams params) async {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    await _connection.writeStanzaWithQueue(requestStanza);
    return responseHandler.set<OMEMOGetDevicesResponse>(
        requestStanza.id!, requestStanza,
        description: 'Fetching user devices');
  }

  @override
  Future<OMEMOPublishDeviceResponse> publishDevice(
      OMEMOPublishDeviceParams params) async {
    final requestStanza = params.buildRequest(from: _connection.fullJid);
    await _connection.writeStanzaWithQueue(requestStanza);
    return responseHandler.set<OMEMOPublishDeviceResponse>(
        requestStanza.id!, requestStanza,
        description: 'Publishing user devices');
  }
}
