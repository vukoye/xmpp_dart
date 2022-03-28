import 'dart:math';

import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomElement.dart';
import 'package:xmpp_stone/src/elements/messages/CustomSubElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeElement.dart';
import 'package:xmpp_stone/src/elements/messages/TimeStampElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOException.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

enum OMEMOEncodedType { utf8, base64, hex, bytes }

/// Success case
///
/// <xmpp_stone>
///   <iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-cdbf4a3a-04ec-413e-841e-03e2490c3d87' id='AQCVFXQRG' type='result'>
///     <pubsub xmlns='http://jabber.org/protocol/pubsub'>
///       <publish node='urn:xmpp:omemo:2:devices'>
///         <item id='current'/>
///       </publish>
///     </pubsub>
///   </iq>
/// </xmpp_stone>
class OMEMOPublishDeviceResponse extends BaseResponse {
  late BaseResponse response;
  late String deviceStoreItemId;
  late bool success;
  static OMEMOPublishDeviceResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = OMEMOPublishDeviceResponse();
    _response.response = response;
    _response.success = response.runtimeType == BaseValidResponse;
    try {
      if (response.runtimeType == BaseValidResponse) {
        // Parse further
        final pubsub = stanza.getChild('pubsub')!;
        final publish = pubsub.getChild('publish')!;
        final item = publish.getChild('item')!;
        _response.deviceStoreItemId = item.getAttribute('id')!.value!;
      }
    } catch (e) {
      _response.deviceStoreItemId = "";
    }

    return _response;
  }
}

class OMEMOGetDevicesResponse extends BaseResponse {
  late BaseResponse response;
  late bool success;
  late List<OMEMODeviceInfo> devices;

  /// Error case:
  ///
  ///
  ///<iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-657e41c8-2225-4ca2-8650-b609084e3256' id='JKHXCJXOH' type='error'>
  ///   <error code='404' type='cancel'><item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
  ///   </error>
  ///   <pubsub xmlns='http://jabber.org/protocol/pubsub'>
  ///    <items node='urn:xmpp:omemo:2:devices'/>
  ///   </pubsub>
  ///   </iq>
  ///
  ///
  /// Success case:
  ///
  /// <xmpp_stone>
  /// <iq from='627775027401@dev2.xmpp.hiapp-chat.com' to='627775027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-96f6a2d3-69fc-4aa4-a0af-6964433055f5' id='VFRSFCMSU' type='result'>
  ///   <pubsub xmlns='http://jabber.org/protocol/pubsub'>
  ///     <items node='urn:xmpp:omemo:2:devices'>
  ///       <item id='current'>
  ///         <devices xmlns='urn:xmpp:omemo:2'>
  ///           <device id='f42af6e50523a5f8' label='Current'/>
  ///         </devices>
  ///       </item>
  ///     </items>
  ///   </pubsub>
  /// </iq>
  /// </xmpp_stone>
  static OMEMOGetDevicesResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = OMEMOGetDevicesResponse();
    _response.response = response;
    _response.success = response.runtimeType == BaseValidResponse;
    try {
      if (response.runtimeType == BaseValidResponse) {
        try {
          // Parse further
          final pubsub = stanza.getChild('pubsub')!;
          final items = pubsub.getChild('items')!;
          final item = items.getChild('item')!;
          final devices = item.getChild('devices')!;
          final List<OMEMODeviceInfo> devicesList = [];
          devices.children.forEach((element) {
            final id = element!.getAttribute('id')!.value!;
            final label = element.getAttribute('label')!.value!;
            devicesList.add(OMEMODeviceInfo(deviceId: id, deviceLabel: label));
          });
          _response.devices = devicesList;
          _response.success = true;
        } catch (e) {
          _response.devices = [];
          _response.success = false;
        }
      }
    } catch (e) {
      throw ErrorGetDevicesException();
    }

    return _response;
  }
}

class OMEMOBundleResult {
  late String ik;
  late String spks;
  late OMEMOPreKeyParams spk;
  late OMEMOPreKeyParams pk;
  late String deviceId;
  late String registrationId;
}

class OMEMOGetBundleResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
  late List<OMEMOBundleResult> bundles;
  final OMEMOEncodedType encoding = OMEMOEncodedType.base64;

  /// Success response:
  /// <iq from="627775027401@dev2.xmpp.hiapp-chat.com" to="627075027401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-7fb4b60e-90db-4f93-bbff-bc9faa4641a6" id="SFRCDOWSK" type="result">
  // <pubsub xmlns="http://jabber.org/protocol/pubsub">
  //   <items node="urn:xmpp:omemo:2:bundles">
  //     <item id="f42af6e50523a5f8">
  //       <bundle xmlns="urn:xmpp:omemo:2">
  //         <spk id="9">CAkSKgogq8kxU9QW7CYQutKrc6cf7aursyn2ftMz3Wf+LHzSOkcSBngyNTUxOQ==</spk>
  //         <spks>zkZVElag8oB3O9wyeJNqkOYwF+BZig7pKHmXtoCJmxQiwff/FKhRJw2F6nRrzKOgtfoHaW6tUiN7KDEJidHbCA==</spks>
  //         <ik>CiBfnki2HDbhvU1cX9EKgCSDFLeihStylN6aIG5zPEnxXBIGeDI1NTE5</ik>
  //         <prekeys>
  //           <pk id="11453">CL1ZEkwKIEB8J+E0dIdB6t5BM/K2xg1v4YYjncoJ1MTJj2rlwWJvEiDMXoBHI/pWYdAbI4v3t5BrgFjfmMgIvUruKoOy4NRNPhoGeDI1NTE5</pk>
  //           <pk id="11454">CL5ZEkwKIAgTSu53vrkGiVRWLQ9IYPHIB9Dwql/tAGPJ7oMa7AVQEiAoFUItlHFMMxz381FuqiGpbBqZblMG6GMomnYRjV4GSBoGeDI1NTE5</pk>
  //        </prekeys>
//         </bundle>
//       </item>
//     </items>
//   </pubsub>
// </iq>
  static OMEMOGetBundleResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = OMEMOGetBundleResponse();
    _response.response = response;
    _response.success = response.runtimeType == BaseValidResponse;
    try {
      if (response.runtimeType == BaseValidResponse) {
        try {
          final pubsub = stanza.getChild('pubsub')!;
          final items = pubsub.getChild('items')!;
          _response.bundles = [];
          for (var item in items.children) {
            final bundle = item!.getChild('bundle')!;
            final spk = bundle.getChild('spk')!;
            final spks = bundle.getChild('spks')!;
            final ik = bundle.getChild('ik')!;
            final preKeys = bundle.getChild('prekeys')!.children;
            final OMEMOBundleResult bundleResult = OMEMOBundleResult();
            bundleResult.deviceId = item.getAttribute('id')!.value!;
            bundleResult.ik = ik.textValue!;
            bundleResult.spks = spks.textValue!;
            bundleResult.spk = OMEMOPreKeyParams(
                id: spk.getAttribute('id')!.value!, pk: spk.textValue!);
            List<OMEMOPreKeyParams> listPreKeys = [];
            preKeys.forEach((element) {
              listPreKeys.add(OMEMOPreKeyParams(
                  id: element!.getAttribute('id')!.value!,
                  pk: element.textValue!));
            });
            final randomId = Random.secure().nextInt(preKeys.length);
            final pk = listPreKeys[randomId];

            bundleResult.pk = pk;
            bundleResult.registrationId = '';
            _response.bundles.add(bundleResult);
          }
          _response.success = true;
        } catch (e) {
          _response.success = false;
        }
      }
    } catch (e) {
      throw ErrorGetDevicesException();
    }

    return _response;
  }
}

class OMEMOPublishBundleResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
  late String deviceId;

  /// Success response:
  /// <xmpp_stone><iq from='627075827401@dev2.xmpp.hiapp-chat.com' to='627075827401@dev2.xmpp.hiapp-chat.com/Android-f42af6e50523a5f8-a556406d-1756-446d-be30-973895f83314' id='JHRVSASTL' type='result'>
  /// <pubsub xmlns='http://jabber.org/protocol/pubsub'>
  /// <publish node='urn:xmpp:omemo:2:bundles'>
  /// <item id='f42af6e50523a5f8'/></publish></pubsub></iq></xmpp_stone>
  static OMEMOPublishBundleResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = OMEMOPublishBundleResponse();
    _response.response = response;
    _response.success = response.runtimeType == BaseValidResponse;
    try {
      if (response.runtimeType == BaseValidResponse) {
        try {
          // Parse further
          final pubsub = stanza.getChild('pubsub')!;
          final publish = pubsub.getChild('publish')!;
          final item = publish.getChild('item')!;
          _response.deviceId = item.getAttribute('id')!.value!;
          _response.success = true;
        } catch (e) {
          _response.success = false;
        }
      }
    } catch (e) {
      _response.success = false;
    }

    return _response;
  }
}

class OMEMOEnvelopePlainTextResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
  late String envelopedPlaintext;

  static OMEMOEnvelopePlainTextResponse parse(String envelopedPlaintext) {
    final response = OMEMOEnvelopePlainTextResponse();
    response.success = true;
    response.response = BaseValidResponse();
    response.envelopedPlaintext = envelopedPlaintext;
    return response;
  }
}

class OMEMOEnvelopePlainTextParseResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
  late String body;
  late String time;
  late String rpad;
  late String customString;
  late String from;

  static OMEMOEnvelopePlainTextParseResponse parse(
      AbstractStanza? xmppElement) {
    final response = OMEMOEnvelopePlainTextParseResponse();
    response.success = true;
    response.response = BaseValidResponse();

    try {
      final envelope = xmppElement!.getChild('envelope');
      final content = envelope!.getChild('content');
      final time =
          TimeStampElement.parse(TimeElement.parse(content)).textValue!;

      final bool hasCustom = CustomElement.parse(content) != null;
      final customString = hasCustom
          ? CustomSubElement.parse(CustomElement.parse(content))!.textValue ??
              ''
          : '';
      final body = content!.getChild('body')!.textValue ?? '';
      final from = envelope.getChild('from')!.getAttribute('jid')!.value!;
      final rpad = envelope.getChild('rpad')!.textValue ?? '';

      response.body = body;
      response.time = time;
      response.customString = customString;
      response.from = from;
      response.rpad = rpad;
    } catch (e) {
      response.success = false;
      response.response = BaseErrorResponse();
    }
    return response;
  }
}

class OMEMOEnvelopeEncryptionResponse extends BaseResponse {
  late bool success;
  late BaseResponse response;
  late EncryptElement encryptEnvelope;

  static OMEMOEnvelopeEncryptionResponse parse(EncryptElement encryptEnvelope) {
    final response = OMEMOEnvelopeEncryptionResponse();
    response.success = true;
    response.response = BaseValidResponse();
    response.encryptEnvelope = encryptEnvelope;
    return response;
  }
}
