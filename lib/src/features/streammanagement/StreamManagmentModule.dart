import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:xmpp_stone/src/elements/nonzas/ANonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/EnableNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/EnabledNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/FailedNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/RNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/ResumeNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/ResumedNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/SMNonza.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamState.dart';

import '../../../xmpp_stone.dart';
import '../Negotiator.dart';

class StreamManagementModule extends Negotiator {
  static const TAG = 'StreamManagementModule';

  static Map<Connection, StreamManagementModule> instances = {};

  static StreamManagementModule getInstance(Connection connection) {
    var module = instances[connection];
    if (module == null) {
      module = StreamManagementModule(connection);
      instances[connection] = module;
    }
    return module;
  }

  static void removeInstance(Connection connection) {
    var instance = instances[connection];
    instance?.timer?.cancel();
    instance?.inNonzaSubscription?.cancel();
    instance?.outStanzaSubscription?.cancel();
    instance?._xmppConnectionStateSubscription.cancel();
    instances.remove(connection);
  }

  StreamState streamState = StreamState();
  final Connection _connection;
  late StreamSubscription<XmppConnectionState> _xmppConnectionStateSubscription;
  StreamSubscription<AbstractStanza?>? inStanzaSubscription;
  StreamSubscription<AbstractStanza>? outStanzaSubscription;
  StreamSubscription<Nonza>? inNonzaSubscription;

  bool ackTurnedOn = true;
  Timer? timer;

  final StreamController<AbstractStanza> _deliveredStanzasStreamController =
      StreamController.broadcast();

  Stream<AbstractStanza> get deliveredStanzasStream {
    return _deliveredStanzasStreamController.stream;
  }

  void sendAckRequest() {
    if (ackTurnedOn) {
      _connection.writeNonza(RNonza());
    }
  }

  void parseAckResponse(String rawValue) {
    var lastDeliveredStanza = int.parse(rawValue);
    var shouldStay = streamState.lastSentStanza - lastDeliveredStanza;
    if (shouldStay < 0) shouldStay = 0;
    while (streamState.nonConfirmedSentStanzas.length > shouldStay) {
      var stanza =
          streamState.nonConfirmedSentStanzas.removeFirst() as AbstractStanza;
      if (ackTurnedOn) {
        _deliveredStanzasStreamController.add(stanza);
      }
      if (stanza.id != null) {
        Log.d(TAG, 'Delivered: ${stanza.id}');
      } else {
        Log.d(TAG, 'Delivered stanza without id ${stanza.name}');
      }
    }
  }

  StreamManagementModule(this._connection) {
    _connection.streamManagementModule = this;
    ackTurnedOn = _connection.account.ackEnabled;
    expectedName = 'StreamManagementModule';
    _xmppConnectionStateSubscription =
        _connection.connectionStateStream.listen((state) {
      if (state == XmppConnectionState.Reconnecting) {
        backToIdle();
      }
      if (!_connection.isOpened() && timer != null) {
        timer!.cancel();
      }
      ;
      if (state == XmppConnectionState.Closed) {
        timer?.cancel();
        inNonzaSubscription?.cancel();
        outStanzaSubscription?.cancel();
        inStanzaSubscription?.cancel();
        _xmppConnectionStateSubscription.cancel();
        streamState = StreamState();
        //state = XmppConnectionState.Idle;
      }
    });
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    var nonza = requests.firstWhereOrNull((request) => SMNonza.match(request));
    return nonza != null ? [nonza] : [];
  }

  //TODO: Improve
  @override
  void negotiate(List<Nonza> nonzas) {
    if (nonzas.isNotEmpty &&
        SMNonza.match(nonzas[0]) &&
        _connection.authenticated) {
      state = NegotiatorState.NEGOTIATING;
      if (inNonzaSubscription == null) {
        inNonzaSubscription = _connection.inNonzasStream.listen(parseNonza);
      }
      //inNonzaSubscription = _connection.inNonzasStream.listen(parseNonza);
      if (streamState.isResumeAvailable()) {
        tryToResumeStream();
      } else {
        sendEnableStreamManagement();
      }
    }
  }

  @override
  bool isReady() {
    return super.isReady() &&
        (isResumeAvailable() ||
            (_connection.fullJid.resource != null &&
                _connection.fullJid.resource!.isNotEmpty));
  }

  void parseNonza(Nonza nonza) {
    if (state == NegotiatorState.NEGOTIATING) {
      if (EnabledNonza.match(nonza)) {
        handleEnabled(nonza);
      } else if (ResumedNonza.match(nonza)) {
        resumeState(nonza);
      } else if (FailedNonza.match(nonza)) {
        if (streamState.tryingToResume) {
          Log.d(TAG, 'Resuming failed');
          streamState = StreamState();
          state = NegotiatorState.DONE;
          negotiatorStateStreamController = StreamController();
          state = NegotiatorState.IDLE; //we will try again
        } else {
          Log.d(TAG,
              'StreamManagmentFailed'); //try to send an error down to client
          state = NegotiatorState.DONE;
        }
      }
    } else if (state == NegotiatorState.DONE) {
      if (ANonza.match(nonza)) {
        parseAckResponse(nonza.getAttribute('h')!.value!);
      } else if (RNonza.match(nonza) && streamState.streamManagementEnabled) {
        Log.w(TAG, 'Sending <a> in response to <r>');
        sendAckResponse();
      }
      /*) {
        if (!streamState.streamManagementEnabled) {
          Log.w(TAG, 'Received <r> but stream management is not enabled');
          return;
        }
          Log.w(TAG, 'Sending <a>');
          sendAckResponse();
        }
      }*/
    }
  }

  void parseOutStanza(AbstractStanza stanza) {
    if (!streamState.streamManagementEnabled) return;

    if (stanza is! AbstractStanza) {
      print("⚠️ Unexpected type: ${stanza.runtimeType}");
      return;
    }

    streamState.lastSentStanza++;
    streamState.nonConfirmedSentStanzas.addLast(stanza);
    //if (!streamState.streamManagementEnabled) return;
    //streamState.lastSentStanza++;
    //streamState.nonConfirmedSentStanzas.addLast(stanza);
  }

  void parseInStanza(AbstractStanza? stanza) {
    if (!streamState.streamManagementEnabled) return;
    streamState.lastReceivedStanza++;
  }

  void handleEnabled(Nonza nonza) {
    streamState.streamManagementEnabled = true;
    var resume = nonza.getAttribute('resume');
    if (resume != null && resume.value == 'true') {
      streamState.streamResumeEnabled = true;
      streamState.id = nonza.getAttribute('id')!.value;
    }
    state = NegotiatorState.DONE;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(
      Duration(milliseconds: 5000),
          (Timer t) {
        if (streamState.streamManagementEnabled) {
          sendAckRequest();
        } else {
          Log.d(TAG, 'Skipping ack request – SM not enabled');
        }
      },
    );
    outStanzaSubscription ??= _connection.outStanzasStream.listen((stanzaOrList) {
      if (stanzaOrList is AbstractStanza) {
        // Handle a single stanza
        parseOutStanza(stanzaOrList);
      } else if (stanzaOrList is Iterable) {
        Log.w(TAG, 'Unexpected item type in outStanzasStream list: ${stanzaOrList.runtimeType}');
        // Explicitly cast and check contents of the list
//        for (final item in stanzaOrList) {
//          if (item is AbstractStanza) {
//            parseOutStanza(item);
//          } else {
//            Log.w(TAG, 'Unexpected item type in outStanzasStream list: ${item.runtimeType}');
//          }
//        }
      } else {
        Log.w(TAG, 'Unexpected value from outStanzasStream: ${stanzaOrList.runtimeType}');
      }
    });
    //outStanzaSubscription ??= _connection.outStanzasStream.listen(parseOutStanza);
    inStanzaSubscription ??= _connection.inStanzasStream.listen(parseInStanza);
  }

  void handleResumed(Nonza nonza) {
    parseAckResponse(nonza.getAttribute('h')!.value!);

    state = NegotiatorState.DONE;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(
        Duration(milliseconds: 5000), (Timer t) => sendAckRequest());
  }

  void sendEnableStreamManagement() =>
      _connection.writeNonza(EnableNonza(_connection.account.smResumable));

  void sendAckResponse() {
    if (!streamState.streamManagementEnabled) {
      Log.d(TAG, 'Not sending <a> because SM is not enabled');
      return;
    }
    Log.d(TAG, 'Sending sending <a> because SM enabled');
    _connection.writeNonza(ANonza(streamState.lastReceivedStanza));
  }

//  void sendAckResponse() =>
//      _connection.writeNonza(ANonza(streamState.lastReceivedStanza));

  void tryToResumeStream() {
    if (!streamState.tryingToResume) {
      _connection.writeNonza(
          ResumeNonza(streamState.id, streamState.lastReceivedStanza));
      streamState.tryingToResume = true;
    }
  }

  void resumeState(Nonza resumedNonza) {
    streamState.tryingToResume = false;
    state = NegotiatorState.DONE_CLEAN_OTHERS;
    _connection.setState(XmppConnectionState.Resumed);
    handleResumed(resumedNonza);
  }

  bool isResumeAvailable() => streamState.isResumeAvailable();

  void reset() {
    negotiatorStateStreamController = StreamController();
    backToIdle();
  }
}
