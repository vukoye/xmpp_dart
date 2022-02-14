import 'package:uuid/uuid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'models/xmpp_communication_callback.dart';

class User {
  String name = '';
  String jid = '';
  String password = '';
  XmppCommunicationCallback xmppCallback;

  late XMPPClientManager xmppClientManager;

  User(this.name, this.jid, this.password, this.xmppCallback);

  void connect(onReady){
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
        xmppCallback.onMessage(message);
      },
      onPresence: (PresenceData presenceData) async {
       

      },
      onPresenceSubscription: (SubscriptionEvent subscriptionEvent) async {
      
      },
      onPing: () async {
      
      },
      // onArchiveRetrieved: (AbstractStanza stanza) {
      //     log('Flutter dart finishing retrieval of archive : ${stanza.buildXmlString()})');
      // },
      onState: (XmppConnectionState state) {
        print('status of ${this.name} ' + state.toString());
      },
    );
    xmppClientManager.createSession();
  }

  void sendMessage({required String message, required User user}){
    const _uuid = Uuid();
    final messageId = _uuid.v1();
    final time = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    xmppClientManager.sendMessage(message,
        user.jid.replaceAll("+", ""),
        additional: MessageParams(
          receipt: ReceiptRequestType.REQUEST,
          messageId: messageId,
          millisecondTs: int.tryParse(time) ??
              DateTime.now().toUtc().millisecondsSinceEpoch,
          customString: '',
          chatStateType: ChatStateType.None,
          messageType: MessageStanzaType.CHAT,
          options: const XmppCommunicationConfig(shallWaitStanza: false),
        ),);
  }

  Future<void> createGroup({required String roomName, required List<String> usersJid}) async {
    xmppClientManager.createInstantRoom(
        roomName,
        GroupChatroomParams.build(
            name: roomName, description: roomName));
    xmppClientManager.getReservedRoomConfig(roomName);
    xmppClientManager.setRoomConfig(
        roomName,
        GroupChatroomParams.build(
          name: roomName,
          description: roomName,
        ));

    final success = await xmppClientManager.addMembersInGroupAsync(roomName, usersJid);
    print(success.toString());
  }

  Future<void> removeMembersInGroup({required String roomName, required List<String> usersJid}) async {
    final success = await xmppClientManager.removeMembersInGroupAsync(roomName, usersJid);
    print(success.toString());
  }

  Future<List<dynamic>> getMembers({required String roomName}) async {
    final GroupChatroom gc = await xmppClientManager.getMembers(roomName);
    final members = gc.groupMembers.map((member) => member.fullJid).toList();
    return members;
  }

  Future<List<dynamic>> getAdmins({required String roomName}) async {
    final GroupChatroom gc = await xmppClientManager.getAdmins(roomName);
    final members = gc.groupMembers.map((member) => member.fullJid).toList();
    return members;
  }

  Future<List<dynamic>> getOwners({required String roomName}) async {
    final GroupChatroom gc = await xmppClientManager.getOwners(roomName);
    final members = gc.groupMembers.map((member) => member.fullJid).toList();
    return members;
  }


}