import 'package:xmpp_stone/src/access_point/communication_config.dart';
import 'package:xmpp_stone/src/extensions/multi_user_chat/MultiUserChatData.dart';

class MultiUserChatCreateParams {
  final GroupChatroomConfig config;
  final XmppCommunicationConfig options;
  const MultiUserChatCreateParams({
    required this.config,
    required this.options,
  });

  static MultiUserChatCreateParams build({
    GroupChatroomConfig config = const GroupChatroomConfig(
        name: '',
        description: '',
        enablelogging: false,
        changesubject: false,
        allowinvites: true,
        allowPm: false,
        maxUser: 20,
        presencebroadcast: ['moderator', 'participant', 'visitor'],
        getmemberlist: ['moderator', 'participant', 'visitor'],
        publicroom: false,
        persistentroom: true,
        membersonly: true,
        passwordprotectedroom: false),
    XmppCommunicationConfig options =
        const XmppCommunicationConfig(shallWaitStanza: false),
  }) {
    return MultiUserChatCreateParams(config: config, options: options);
  }
}

class MultiUserChatQueryParams {
  final XmppCommunicationConfig options;
  const MultiUserChatQueryParams({
    required this.options,
  });

  static MultiUserChatQueryParams build({
    XmppCommunicationConfig options =
        const XmppCommunicationConfig(shallWaitStanza: false),
  }) {
    return MultiUserChatQueryParams(options: options);
  }
}
