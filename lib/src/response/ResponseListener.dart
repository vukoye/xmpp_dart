import 'package:xmpp_stone/src/response/BaseResponse.dart';

abstract class ResponseListener {
  void onResponse(BaseResponse state);
}
