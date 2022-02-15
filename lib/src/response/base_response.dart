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
          errorResponse.code = error.getAttribute('code')!.value!;
          final itemNotFound = error.getChild('item-not-found');

          XmppElement? textItem = error.children.firstWhere(
              (element) => element!.name == 'text',
              orElse: () => XmppElement());

          if (textItem != null && textItem.textValue != null) {
            errorResponse.message = textItem.textValue!;
          } else if (itemNotFound != null) {
            errorResponse.message = 'Item not found';
          } else {
            errorResponse.message = 'Unidentified error';
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
}

class BaseValidResponse extends BaseResponse {}
