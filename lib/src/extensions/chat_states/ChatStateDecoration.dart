import 'package:xmpp_stone/src/elements/messages/chat_states/ChatStateActiveElement.dart';
import 'package:xmpp_stone/src/elements/messages/chat_states/ChatStateComposingElement.dart';
import 'package:xmpp_stone/src/elements/messages/chat_states/ChatStateGoneElement.dart';
import 'package:xmpp_stone/src/elements/messages/chat_states/ChatStateInactiveElement.dart';
import 'package:xmpp_stone/src/elements/messages/chat_states/ChatStatePausedElement.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

/// Inspired by this https://xmpp.org/extensions/xep-0085.html
///
///
enum ChatStateType {
  None,
  NotApplicable,
  Active,
  Composing,
  Paused,
  Inactive,
  Gone,
}

class ChatStateDecoration {
  final MessageStanza message;
  const ChatStateDecoration({required this.message});

  MessageStanza setState(ChatStateType chatStateType) {
    if (chatStateType == ChatStateType.Active) {
      setActive();
    } else if (chatStateType == ChatStateType.Composing) {
      setComposing();
    } else if (chatStateType == ChatStateType.Paused) {
      setPaused();
    } else if (chatStateType == ChatStateType.Inactive) {
      setInactive();
    } else if (chatStateType == ChatStateType.Gone) {
      setGone();
    }
    return message;
  }

  setActive() {
    final existing = getActive();
    if (existing == null) {
      final active = ChatStateActiveElement.build();
      message.addChild(active);
    }
  }

  setComposing() {
    final existing = getComposing();
    if (existing == null) {
      final active = ChatStateComposingElement.build();
      message.addChild(active);
    }
  }

  setInactive() {
    final existing = getInactive();
    if (existing == null) {
      final active = ChatStateInactiveElement.build();
      message.addChild(active);
    }
  }

  setPaused() {
    final existing = getPaused();
    if (existing == null) {
      final active = ChatStatePausedElement.build();
      message.addChild(active);
    }
  }

  setGone() {
    final existing = getGone();
    if (existing == null) {
      final active = ChatStateGoneElement.build();
      message.addChild(active);
    }
  }

  XmppElement? getActive() {
    final existing = ChatStateActiveElement.parse(message);
    return existing;
  }

  XmppElement? getComposing() {
    final existing = ChatStateComposingElement.parse(message);
    return existing;
  }

  XmppElement? getPaused() {
    final existing = ChatStatePausedElement.parse(message);
    return existing;
  }

  XmppElement? getInactive() {
    final existing = ChatStateInactiveElement.parse(message);
    return existing;
  }

  XmppElement? getGone() {
    final existing = ChatStateGoneElement.parse(message);
    return existing;
  }

  bool get hasState {
    return getActive() != null ||
        getComposing() != null ||
        getPaused() != null ||
        getInactive() != null ||
        getGone() != null;
  }

  String get getState {
    if (!hasState) {
      return '';
    }
    final errorState = message.children.where((element) => [
          'error',
        ].contains(element!.name));
    if (errorState.isNotEmpty) {
      return 'unavailable';
    }
    final state = message.children.where((element) => [
          'active',
          'composing',
          'paused',
          'inactive',
          'gone'
        ].contains(element!.name));
    if (state.isNotEmpty) {
      return state.last!.name!;
    } else {
      return '';
    }
  }
}
