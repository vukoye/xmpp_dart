import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'models/xmpp_communication_callback.dart';

class User {
  String name = '';
  String jid = '';
  String password = '';
  String countryCode = '62';
  String phoneNumber = '';

  XmppCommunicationCallback? xmppCallback;

  late XMPPClientManager xmppClientManager;

  User(
      {required this.name,
      required this.jid,
      required this.password,
      required this.phoneNumber,
      this.countryCode = '62',
      this.xmppCallback = null});

  void connect(onReady) {
    var fullJid = Jid.fromFullJid(this.jid);
    xmppClientManager = XMPPClientManager(
      this.jid,
      this.password,
      onReady: (XMPPClientManager context) {
        context.listens();
        context.presenceSend(PresenceShowElement.CHAT, description: 'Working');
        onReady();
      },
      onLog: (String time, String message) {},
      host: fullJid.domain,
      mucDomain: 'conference.${fullJid.domain}',
      onMessage: (XMPPMessageParams message, ListenerType listenerType) async {
        print('${this.name} recieved message: ${message.message!.body}');
        print('${this.name} ${listenerType.toString()}');
        if (xmppCallback!.onMessage != noFunc) {
          xmppCallback!.onMessage(message);
        }
      },
      onPresence: (PresenceData presenceData) async {
        if (presenceData.presenceStanza != null) {
          print(
              '${this.name} presenceData ${presenceData.presenceStanza?.buildXmlString()}');
        }
      },
      onPresenceSubscription: (SubscriptionEvent subscriptionEvent) async {},
      onPing: () async {},
      // onArchiveRetrieved: (AbstractStanza stanza) {
      //     log('Flutter dart finishing retrieval of archive : ${stanza.buildXmlString()})');
      // },
      onState: (XmppConnectionState state) {
        // print('status of ${this.name} ' + state.toString());
      },
    );
    xmppClientManager.createSession();
  }

  void sendMessage({required String message, required User user}) {
    const _uuid = Uuid();
    final messageId = _uuid.v1();
    final time = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    xmppClientManager.sendMessage(
      message,
      user.jid.replaceAll("+", ""),
      additional: MessageParams(
        receipt: ReceiptRequestType.REQUEST,
        messageId: messageId,
        millisecondTs:
            int.tryParse(time) ?? DateTime.now().toUtc().millisecondsSinceEpoch,
        customString: '',
        chatStateType: ChatStateType.None,
        messageType: MessageStanzaType.CHAT,
        options: const XmppCommunicationConfig(shallWaitStanza: false),
        ampMessageType: AmpMessageType.None,
        hasEncryptedBody: false,
      ),
    );
  }

  Future<void> createGroup(
      {required String roomName, required List<String> usersJid}) async {
    xmppClientManager.createInstantRoom(roomName,
        GroupChatroomParams.build(name: roomName, description: roomName));
    final configResponse =
        await xmppClientManager.getReservedRoomConfig(roomName);
    final roomConfig = configResponse.roomConfigFields;
    final Map<String, RoomConfigField> mappedConfig = {};
    final roomConfigOpts = GroupChatroomParams.build(
      name: roomName,
      description: roomName,
    );

    roomConfig.forEach((element) {
      mappedConfig[element.key] = element;
    });
    if (mappedConfig['muc#roomconfig_roomname'] != null) {
      mappedConfig['muc#roomconfig_roomname']!.setValue(roomName);
    }
    if (mappedConfig['muc#roomconfig_roomdesc'] != null) {
      mappedConfig['muc#roomconfig_roomdesc']!.setValue(roomName);
    }
    if (mappedConfig['muc#roomconfig_lang'] != null) {
      mappedConfig['muc#roomconfig_lang']!.setValue('en');
    }
    if (mappedConfig['muc#roomconfig_persistentroom'] != null) {
      mappedConfig['muc#roomconfig_persistentroom']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_publicroom'] != null) {
      mappedConfig['muc#roomconfig_publicroom']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_presencebroadcast'] != null) {
      mappedConfig['muc#roomconfig_presencebroadcast']!
          .setValue(roomConfigOpts.presencebroadcast);
    }
    if (mappedConfig['muc#roomconfig_membersonly'] != null) {
      mappedConfig['muc#roomconfig_membersonly']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_moderatedroom'] != null) {
      mappedConfig['muc#roomconfig_moderatedroom']!.setValue('1');
    }
    if (mappedConfig['muc#members_by_default'] != null) {
      mappedConfig['muc#members_by_default']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_changesubject'] != null) {
      mappedConfig['muc#roomconfig_changesubject']!.setValue('1');
    }
    if (mappedConfig['allow_private_messages'] != null) {
      mappedConfig['allow_private_messages']!.setValue('1');
    }
    if (mappedConfig['allow_private_messages_from_visitors'] != null) {
      mappedConfig['allow_private_messages_from_visitors']!.setValue('anyone');
    }
    if (mappedConfig['allow_query_users'] != null) {
      mappedConfig['allow_query_users']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_allowinvites'] != null) {
      mappedConfig['muc#roomconfig_allowinvites']!.setValue('1');
    }
    if (mappedConfig['allow_visitor_status'] != null) {
      mappedConfig['allow_visitor_status']!.setValue('1');
    }
    if (mappedConfig['allow_visitor_nickchange'] != null) {
      mappedConfig['allow_visitor_nickchange']!.setValue('1');
    }
    if (mappedConfig['allow_voice_requests'] != null) {
      mappedConfig['allow_voice_requests']!.setValue('1');
    }
    if (mappedConfig['allow_subscription'] != null) {
      mappedConfig['allow_subscription']!.setValue('1');
    }
    if (mappedConfig['voice_request_min_interval'] != null) {
      mappedConfig['voice_request_min_interval']!.setValue('1800');
    }
    if (mappedConfig['muc#roomconfig_pubsub'] != null) {
      mappedConfig['muc#roomconfig_pubsub']!.setValue('');
    }
    if (mappedConfig['voice_request_min_interval'] != null) {
      mappedConfig['voice_request_min_interval']!.setValue('1800');
    }
    if (mappedConfig['mam'] != null) {
      mappedConfig['mam']!.setValue('1');
    }
    // Mongooseim
    if (mappedConfig['muc#roomconfig_allowmultisessions'] != null) {
      mappedConfig['muc#roomconfig_allowmultisessions']!.setValue('1');
    }
    if (mappedConfig['muc#roomconfig_whois'] != null) {
      mappedConfig['muc#roomconfig_whois']!.setValue('anyone');
    }
    if (mappedConfig['muc#roomconfig_getmemberlist'] != null) {
      mappedConfig['muc#roomconfig_getmemberlist']!
          .setValue(roomConfigOpts.getmemberlist);
    }
    xmppClientManager.setRoomConfig(
        roomName, roomConfigOpts, mappedConfig.values.toList());

    final success =
        await xmppClientManager.addMembersInGroupAsync(roomName, usersJid);
    return Future.value(success);
  }

  Future<bool> removeMembersInGroup(
      {required String roomName, required List<String> usersJid}) async {
    final AddUsersResponse success =
        await xmppClientManager.removeMembersInGroupAsync(roomName, usersJid);
    return Future.value(success.success);
  }

  Future<void> addAdminsInGroup(
      {required String roomName, required List<String> usersJid}) async {
    final success =
        await xmppClientManager.addAdminsInGroupAsync(roomName, usersJid);
    return Future.value(success);
  }

  Future<void> removeAdminsInGroup(
      {required String roomName, required List<String> usersJid}) async {
    final success =
        await xmppClientManager.removeAdminsInGroupAsync(roomName, usersJid);
    return Future.value(success);
  }

  Future<List<dynamic>> getMembers({required String roomName}) async {
    final GetUsersResponse gc = await xmppClientManager.getMembers(roomName);
    final members = gc.users.map((member) => member.fullJid).toList();
    return members;
  }

  Future<List<dynamic>> getAdmins({required String roomName}) async {
    final GetUsersResponse gc = await xmppClientManager.getAdmins(roomName);
    final members = gc.users.map((member) => member.fullJid).toList();
    return members;
  }

  Future<List<dynamic>> getOwners({required String roomName}) async {
    final GetUsersResponse gc = await xmppClientManager.getOwners(roomName);
    final members = gc.users.map((member) => member.fullJid).toList();
    return members;
  }

  // Group

  Future<void> sendCustomGroupMessage({required String roomName}) async {
    final messageId = const Uuid().v1();
    final messageDateTime = DateTime.now();
    final customMessage = {
      "iqType": "Notification",
      "subType": "Add-User",
      "groupJid": "test2",
      "userJids": ["kevin"]
    };
    final success = await xmppClientManager.sendMessage(
        '', '${roomName}@conference.localhost',
        additional: MessageParams(
          receipt: ReceiptRequestType.NONE,
          messageId: messageId,
          millisecondTs: DateTime.now().toUtc().millisecondsSinceEpoch,
          customString: jsonEncode(customMessage),
          chatStateType: ChatStateType.None,
          messageType: MessageStanzaType.GROUPCHAT,
          // ampMessageType: 'None',
          options: const XmppCommunicationConfig(shallWaitStanza: false),
          hasEncryptedBody: false, ampMessageType: AmpMessageType.None,
        ));
    return Future.value();
  }
}
