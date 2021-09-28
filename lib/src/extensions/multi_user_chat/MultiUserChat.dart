import 'package:xmpp_stone/src/elements/XmppElement.dart';

class MUCChatroom {
  String serviceCategory;
  String serviceName;
  String serviceType;
  MUCChatroom(this.serviceCategory, this.serviceType, this.serviceName);
}

class MultiUserChat extends XmppElement {
  List<String> features;
  List<MUCChatroom> chatrooms;
  String mucDomain;
}

class InvalidMultiUserChat extends MultiUserChat {}