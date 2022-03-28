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
import 'package:xmpp_stone/src/elements/nonzas/StreamManagementNonza.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamState.dart';

import '../../../xmpp_stone.dart';
import '../Negotiator.dart';

const tag = 'stream-management';

class StreamManagementModule extends Negotiator {
  static const TAG = 'StreamManagementModule';

  static Map<Connection?, StreamManagementModule> instances =
      <Connection?, StreamManagementModule>{};

  static StreamManagementModule getInstance(Connection? connection) {
    var module = instances[connection];
    if (module == null) {
      module = StreamManagementModule(connection!);
      instances[connection] = module;
    }
    return module;
  }

  StreamState streamState = StreamState();
  late Connection _connection;
  StreamSubscription<AbstractStanza?>? inStanzaSubscription;
  StreamSubscription<AbstractStanza>? outStanzaSubscription;
  StreamSubscription<Nonza>? inNonzaSubscription;

  bool ackTurnedOn = true;
  bool enablingStream = false;
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

  StreamManagementModule(Connection connection) {
    _connection = connection;
    _connection.streamManagementModule = this;
    ackTurnedOn = connection.account.ackEnabled;
    expectedName = 'StreamManagementModule';
    _connection.connectionStateStream.listen((state) {
      if (state == XmppConnectionState.Reconnecting) {
        backToIdle();
      }
      if (!_connection.isOpened() && timer != null) {
        resetAckTimer();
      }
      ;
      if (state == XmppConnectionState.Closed) {
        streamState = StreamState();
      }
    });
  }

  @override
  List<Nonza> match(List<Nonza> requests) {
    var nonza = requests
        .where((request) => SMNonza.match(request) || SMNonza.matchV2(request));
    return nonza.toList();
  }

// Assume if we need for this.
  _matchSMV2(List<Nonza> nonzas) {
    bool result = false;
    nonzas.forEach((element) {
      result = SMNonza.matchV2(element) || result;
    });
    return result;
  }

// Assume if we need for this.
  _matchSMV3(List<Nonza> nonzas) {
    bool result = false;
    nonzas.forEach((element) {
      result = SMNonza.match(element) || result;
    });
    return result;
  }

  //TODO: Improve
  @override
  void negotiate(List<Nonza> nonzas) {
    if (nonzas != null && nonzas.isNotEmpty && _connection.authenticated) {
      bool matchSm2 = _matchSMV2(nonzas);
      // Somehow, it listens too many times, if we don't clear or check.
      // TOOD: see when to send from here and when not to....
      // Ejabberd has version 2 support, I just check on it, but to be see if we need
      // to this.
      if (matchSm2) {
        sendEnableStreamManagement(resume: true);
      }
      bool matchSm3 = _matchSMV3(nonzas);
      if (matchSm2 || matchSm3) {
        state = NegotiatorState.NEGOTIATING;
        enablingStream = false;
        if (inNonzaSubscription == null) {
          inNonzaSubscription = _connection.inNonzasStream.listen(parseNonza);
        }
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
        print('<enable state done?  ${state}');
        Log.d(tag, 'Handle <enable> stream done');

        enablingStream = false;
        handleEnabled(nonza);
      } else if (ResumedNonza.match(nonza)) {
        resumeState(nonza);
      } else if (StreamNonza.match(nonza)) {
        Log.d(tag, 'Handle <enable> stream started: $enablingStream');
        if (!enablingStream) {
          sendEnableStreamManagement(resume: true);
          enablingStream = true;
        }
      } else if (FailedNonza.match(nonza)) {
        if (streamState.tryingToResume) {
          Log.d(TAG, 'Resuming failed');
          enablingStream = false;
          streamState = StreamState();
          state = NegotiatorState.DONE;
          negotiatorStateStreamController = StreamController();
          state = NegotiatorState.IDLE; //we will try again
        } else {
          Log.d(TAG,
              'Stream Management Failed'); // try to send an error down to client
          state = NegotiatorState.DONE;
        }
        // On stream resume failed, try to tell connection to handle error, close and then open again
        _connection.handleStreamConflictErrorThrown();
      }
    } else if (state == NegotiatorState.DONE) {
      if (ANonza.match(nonza)) {
        parseAckResponse(nonza.getAttribute('h')!.value!);
      } else if (RNonza.match(nonza)) {
        sendAckResponse();
      }
    }
  }

  void parseOutStanza(AbstractStanza stanza) {
    streamState.lastSentStanza++;
    streamState.nonConfirmedSentStanzas.addLast(stanza);
  }

  void parseInStanza(AbstractStanza? stanza) {
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
        Duration(milliseconds: 5000), (Timer t) => sendAckRequest());
    outStanzaSubscription = _connection.outStanzasStream.listen(parseOutStanza);
    inStanzaSubscription = _connection.inStanzasStream.listen(parseInStanza);
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

  void sendEnableStreamManagement({bool resume = false}) =>
      _connection.writeNonza(EnableNonza(resume));

  void sendAckResponse() =>
      _connection.writeNonza(ANonza(streamState.lastReceivedStanza));

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

  void resetAckTimer() {
    streamState = StreamState();
    streamState.lastReceivedStanza = 0;
    streamState.lastSentStanza = 0;
    timer!.cancel();

    outStanzaSubscription!.cancel();
    inStanzaSubscription!.cancel();
  }

  void reset() {
    negotiatorStateStreamController = StreamController();
    backToIdle();
  }
}
