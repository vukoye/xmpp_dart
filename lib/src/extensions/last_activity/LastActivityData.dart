import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/extensions/last_activity/LastActivityManager.dart';
import 'package:xmpp_stone/src/response/BaseResponse.dart';

class LastActivityResponse extends BaseResponse {
  late String lastActivitySeconds;
  late BaseResponse response;
  late bool success;

  static LastActivityResponse parse(AbstractStanza stanza) {
    final response = BaseResponse.parseError(stanza);
    final _response = LastActivityResponse();
    _response.response = response;
    _response.success = response.runtimeType == BaseValidResponse;
    _response.lastActivitySeconds = "";
    try {
      if (response.runtimeType == BaseValidResponse) {
        final queryElement = stanza.getChild('query');
        if (queryElement != null &&
            queryElement.getAttribute('xmlns')!.value == iqLastActivityXmlns) {
          final lastActivitySeconds =
              queryElement.getAttribute('seconds')!.value;
          _response.lastActivitySeconds = lastActivitySeconds ?? "";
          _response.success = true;
        }
      }
    } catch (e) {
      _response.success = false;
      _response.lastActivitySeconds = "";
      _response.response = BaseErrorResponse();
    }

    return _response;
  }
}
