import 'package:xmpp_stone/src/elements/XmppElement.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';

abstract class BaseResponse {
  static parseError(AbstractStanza stanza) {
    if (stanza.name == 'iq') {
      final iqType = stanza.getAttribute('type')!.value;
      if (iqType == 'error') {
        final error = stanza.getChild('error');
        final errorResponse = BaseErrorResponse();
        if (error != null) {
          errorResponse.code = error.getAttribute('code') != null
              ? error.getAttribute('code')!.value!
              : '00';
          final itemNotFound = error.getChild('item-not-found');
          final serviceUnavailable = error.getChild('service-unavailable');
          final notAllowed = error.getChild('not-allowed');

          XmppElement? textItem = error.children.firstWhere(
              (element) => element!.name == 'text',
              orElse: () => XmppElement());

          if (itemNotFound != null) {
            errorResponse.errorType = 'item-not-found';
            errorResponse.message = 'Item not found';
          } else if (serviceUnavailable != null) {
            errorResponse.errorType = 'service-unavailable';
            errorResponse.message = 'Service unavailable';
          } else if (notAllowed != null) {
            errorResponse.errorType = 'not-allowed';
            errorResponse.message = 'Not Allowed';
          } else {
            errorResponse.errorType = 'n/a';
            errorResponse.message = 'Unidentified error';
          }

          if (textItem != null && textItem.textValue != null) {
            errorResponse.message = textItem.textValue!;
          }
        }
        return errorResponse;
      } else if (iqType == 'result') {
        return BaseValidResponse();
      }
    } else if (stanza.name == 'presence') {
      return BaseValidResponse();
    }

    // Return stanza
    final errorResponse = BaseErrorResponse();
    errorResponse.code = 'N/A';
    errorResponse.message = 'Unidentified error';
    return errorResponse;
  }
}

class BaseErrorResponse extends BaseResponse {
  late String code;
  late String message;
  late String errorType;
}

class BaseValidResponse extends BaseResponse {}
