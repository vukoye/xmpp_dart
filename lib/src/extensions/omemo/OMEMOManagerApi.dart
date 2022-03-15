import 'package:xmpp_stone/src/extensions/omemo/OMEMOData.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';

abstract class OMEMOManagerApi {
  Future<OMEMOPublishDeviceResponse> publishDevice(
      OMEMOPublishDeviceParams params);
  Future<OMEMOPublishBundleResponse> publishBundle(
      OMEMOPublishBundleParams params);
  Future<OMEMOGetDevicesResponse> fetchDevices(OMEMOGetDevicesParams params);
  Future<OMEMOGetBundleResponse> fetchBundle(OMEMOGetBundleParams params);
  Future<OMEMOEnvelopePlainTextResponse> envelopePlainContent(
      OMEMOEnvelopePlainTextParams params);
  Future<OMEMOEnvelopePlainTextParseResponse> parseEnvelopePlainContent(
      OMEMOEnvelopeParsePlainTextParams params);
  Future<OMEMOEnvelopeEncryptionResponse> envelopeEncryptionContent(
      OMEMOEnvelopeEncryptionParams params);
}
