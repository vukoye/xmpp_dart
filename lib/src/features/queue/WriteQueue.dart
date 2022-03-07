import 'dart:async';

import 'package:xmpp_stone/src/features/queue/QueueApi.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

class WriteQueueContent {
  final AbstractStanza stanza;
  final bool postInitializationStanza;

  const WriteQueueContent(this.stanza, this.postInitializationStanza);
}

class WriteQueue extends QueueApi<WriteQueueContent> {
  List<WriteQueueContent> writingQueueContent = [];
  Connection? _connection;
  bool isRunning = false;

  WriteQueue(Connection? connection) {
    _connection = connection;
    writingQueueContent = [];

    // Resume queue
    _connection!.connectionStateStream.listen((state) {
      if (state == XmppConnectionState.Ready) {
        resume();
      } else {
        isRunning = false;
      }
    });
  }

  @override
  put(WriteQueueContent content) {
    writingQueueContent.add(content);
  }

  @override
  resume() async {
    if (isRunning) {
      return;
    }
    isRunning = true;
    await _resume();
  }

  _resume() async {
    if (writingQueueContent.isEmpty) {
      isRunning = false;
      return;
    }
    bool shouldResume = await pop();
    // Can continue
    if (shouldResume) {
      await _resume();
    } else {
      isRunning = false;
    }
  }

  bool _isEligible(WriteQueueContent content) {
    if (!content.postInitializationStanza) {
      return true;
    } else {
      return (_connection!.state == XmppConnectionState.Ready);
    }
  }

  @override
  bool isEligible() {
    return (_connection!.state == XmppConnectionState.Ready);
  }

  @override
  Future<bool> execute(WriteQueueContent content) async {
    final Completer<bool> completer = Completer<bool>();
    Timer(const Duration(milliseconds: 300), () {
      _connection!.writeStanza(content.stanza,
          postInitialization: content.postInitializationStanza);
      completer.complete(true);
    });
    return completer.future;
  }

  @override
  Future<bool> pop() async {
    bool isEligible = await _isEligible(writingQueueContent.elementAt(0));
    if (isEligible) {
      final content = writingQueueContent.removeAt(0);
      await execute(content);
      return true;
    } else {
      return false;
    }
  }

  @override
  clear() {
    writingQueueContent = [];
  }
}
