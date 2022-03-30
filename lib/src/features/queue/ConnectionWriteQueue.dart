import 'dart:async';
import 'dart:collection';

import 'package:xmpp_stone/src/Connection.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/exception/XmppException.dart';
import 'package:xmpp_stone/src/features/queue/QueueApi.dart';
import 'package:xmpp_stone/src/logger/Log.dart';

const tag = 'wrt-queue';

class WriteContent {
  final String id;
  final AbstractStanza content;
  final bool sent;

  const WriteContent(
      {required this.id, required this.content, required this.sent});

  WriteContent copyWith({String? id, AbstractStanza? content, bool? sent}) {
    return WriteContent(
        id: id ?? this.id,
        content: content ?? this.content,
        sent: sent ?? this.sent);
  }
}

class ConnectionWriteQueue extends QueueApi {
  static int idealWriteIntervalMs = 200;
  Queue<WriteContent> writingQueueContent = Queue<WriteContent>();
  late Connection _connection;
  late StreamController<AbstractStanza> _outStanzaStreamController;
  bool isRunning = false;

  ConnectionWriteQueue(Connection connection,
      StreamController<AbstractStanza> outStanzaStreamController) {
    writingQueueContent.clear();
    _connection = connection;
    _connection.connectionStateStream.listen(_connectionStateHandler);
    _outStanzaStreamController = outStanzaStreamController;
  }

  void _connectionStateHandler(XmppConnectionState state) async {
    if (state == XmppConnectionState.Ready) {
      await resume();
    }
  }

  @override
  clear() {
    writingQueueContent.clear();
  }

  @override
  Future<bool> execute(content) {
    final wrtContent = content as WriteContent;
    final Completer<bool> completer = Completer<bool>();
    Timer(Duration(milliseconds: idealWriteIntervalMs), () {
      bool success = true;
      try {
        _connection.writeStanza(wrtContent.content);
        _outStanzaStreamController.add(wrtContent.content);
      } on FailWriteSocketException {
        Log.e(tag, 'Fail to write to socket');
        success = false;
      } catch (e) {
        Log.e(tag, 'Fail to write to socket with other error $e');
        success = false;
      }
      completer.complete(success);
    });
    return completer.future;
  }

  @override
  bool isEligible() {
    return _connection.state == XmppConnectionState.Ready;
  }

  @override
  Future<bool> pop() async {
    bool _isEligible = isEligible();
    if (_isEligible) {
      final wrtContent = writingQueueContent.removeFirst();
      final successExecute = await execute(wrtContent);
      if (!successExecute) {
        writingQueueContent.addFirst(wrtContent);
      }
      return successExecute;
    } else {
      return false;
    }
  }

  @override
  put(content) {
    final wrtContent = content as WriteContent;
    writingQueueContent.add(wrtContent);
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
      throw FailWriteSocketException();
    }
  }
}
