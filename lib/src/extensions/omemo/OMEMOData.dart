import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOException.dart';
import 'package:xmpp_stone/src/extensions/omemo/OMEMOParams.dart';

abstract class OMEMOResponse {
  static parseError(AbstractStanza stanza) {
    final iqType = stanza.getAttribute('type')!.value;
    if (iqType == 'error') {
      final error = stanza.getChild('error');
      final errorResponse = OMEMOErrorResponse();
      if (error != null) {
        errorResponse.code = error.getAttribute('code')!.value!;
        final itemNotFound = error.getChild('item-not-found');
        if (itemNotFound != null) {
          errorResponse.message = 'Item not found';
        } else {
          errorResponse.message = 'Unidentified error';
        }
      }
      return errorResponse;
    }
    if (iqType == 'result') {
      return OMEMOValidResponse();
    } else {
      final errorResponse = OMEMOErrorResponse();
      errorResponse.code = 'N/A';
      errorResponse.message = 'Unidentified error';
      return errorResponse;
    }
  }
}

class OMEMOErrorResponse extends OMEMOResponse {
  late String code;
  late String message;
}

class OMEMOValidResponse extends OMEMOResponse {}

class OMEMOPublishBundleResponse extends OMEMOResponse {}

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
class OMEMOPublishDeviceResponse extends OMEMOResponse {
  late OMEMOResponse response;
  late String deviceStoreItemId;
  static OMEMOPublishDeviceResponse parse(AbstractStanza stanza) {
    final response = OMEMOResponse.parseError(stanza);
    final _response = OMEMOPublishDeviceResponse();
    _response.response = response;
    try {
      if (response.runtimeType == OMEMOValidResponse) {
        // Parse further
        final pubsub = stanza.getChild('pubsub')!;
        final publish = pubsub.getChild('publish')!;
        final item = publish.getChild('item')!;
        _response.deviceStoreItemId = item.getAttribute('id')!.value!;
      }
    } catch (e) {
      throw ErrorPublishDeviceException();
    }

    return _response;
  }
}

class OMEMOGetDevicesResponse extends OMEMOResponse {
  late OMEMOResponse response;
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
    final response = OMEMOResponse.parseError(stanza);
    final _response = OMEMOGetDevicesResponse();
    _response.response = response;
    try {
      if (response.runtimeType == OMEMOValidResponse) {
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
      }
    } catch (e) {
      throw ErrorGetDevicesException();
    }

    return _response;
  }
}

class OMEMOGetBundleResponse extends OMEMOResponse {}

class OMEMOEnvelopePlainTextResponse extends OMEMOResponse {}

class OMEMOEnvelopeEncryptionResponse extends OMEMOResponse {}
