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

  User({required this.name, required this.jid, required this.password,required this.phoneNumber, this.countryCode = '62', this.xmppCallback = null});

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
        if (xmppCallback!.onConnectionStatus != noFunc) {
          xmppCallback!.onConnectionStatus(state);
        }
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
    await xmppClientManager.createInstantRoom(roomName,
        GroupChatroomParams.build(name: roomName, description: roomName));
    await xmppClientManager.getReservedRoomConfig(roomName);
    await xmppClientManager.setRoomConfig(
        roomName,
        GroupChatroomParams.build(
          name: roomName,
          description: roomName,
        ));

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
  void sendGroupMessage({required String roomName, required String message}) {
    const _uuid = Uuid();
    final messageId = _uuid.v1();
    final time = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    xmppClientManager.sendMessage(
      message,
      '${roomName}@conference.localhost',
      additional: MessageParams(
        receipt: ReceiptRequestType.NONE,
        messageId: messageId,
        millisecondTs:
            int.tryParse(time) ?? DateTime.now().toUtc().millisecondsSinceEpoch,
        customString: '',
        chatStateType: ChatStateType.None,
        messageType: MessageStanzaType.GROUPCHAT,
        options: const XmppCommunicationConfig(shallWaitStanza: false),
        ampMessageType: AmpMessageType.None,
        hasEncryptedBody: false,
      ),
    );
  }

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
