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
    instance?.inNonzaSubscription?.cancel();
    instance?._xmppConnectionStateSubscription.cancel();
    instances.remove(connection);
  }

  StreamState streamState = StreamState();
  final Connection _connection;
  late StreamSubscription<XmppConnectionState> _xmppConnectionStateSubscription;
  StreamSubscription<AbstractStanza?>? inStanzaSubscription;
  StreamSubscription<AbstractStanza>? outStanzaSubscription;
  StreamSubscription<Nonza>? inNonzaSubscription;

  bool _ackTurnedOn = true;
  Timer? timer;

  final StreamController<AbstractStanza> _deliveredStanzasStreamController =
      StreamController.broadcast();

  Stream<AbstractStanza> get deliveredStanzasStream {
    return _deliveredStanzasStreamController.stream;
  }

  void _sendAckRequest() {
    if (_ackTurnedOn) {
      _connection.writeNonza(RNonza());
    }
  }

  void _parseAckResponse(String rawValue) {
    var lastDeliveredStanza = int.parse(rawValue);
    var shouldStay = streamState.lastSentStanza - lastDeliveredStanza;
    if (shouldStay < 0) shouldStay = 0;
    while (streamState.nonConfirmedSentStanzas.length > shouldStay) {
      var stanza =
          streamState.nonConfirmedSentStanzas.removeFirst() as AbstractStanza;
      if (_ackTurnedOn) {
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
    _ackTurnedOn = _connection.account.ackEnabled;
    expectedName = 'StreamManagementModule';
    _xmppConnectionStateSubscription =
        _connection.connectionStateStream.listen((state) {
      if (state == XmppConnectionState.Reconnecting) {
        backToIdle();
      }
      if (!_connection.isOpened() && timer != null) {
        timer!.cancel();
      }
      if (state == XmppConnectionState.Closed) {
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
      inNonzaSubscription = _connection.inNonzasStream.listen(_parseNonza);
      if (streamState.isResumeAvailable()) {
        _tryToResumeStream();
      } else {
        _sendEnableStreamManagement();
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

  void _parseNonza(Nonza nonza) {
    if (state == NegotiatorState.NEGOTIATING) {
      if (EnabledNonza.match(nonza)) {
        _handleEnabled(nonza);
      } else if (ResumedNonza.match(nonza)) {
        _resumeState(nonza);
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
    }

    if (ANonza.match(nonza)) {
      _parseAckResponse(nonza.getAttribute('h')!.value!);
    } else if (RNonza.match(nonza)) {
      _sendAckResponse();
    }
  }

  void _parseOutStanza(AbstractStanza stanza) {
    streamState.lastSentStanza++;
    streamState.nonConfirmedSentStanzas.addLast(stanza);
  }

  void _parseInStanza(AbstractStanza? stanza) {
    streamState.lastReceivedStanza++;
  }

  void _handleEnabled(Nonza nonza) {
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
        Duration(milliseconds: 5000), (Timer t) => _sendAckRequest());
    outStanzaSubscription =
        _connection.outStanzasStream.listen(_parseOutStanza);
    inStanzaSubscription = _connection.inStanzasStream.listen(_parseInStanza);
  }

  void _handleResumed(Nonza nonza) {
    _parseAckResponse(nonza.getAttribute('h')!.value!);

    state = NegotiatorState.DONE;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(
        Duration(milliseconds: 5000), (Timer t) => _sendAckRequest());
  }

  void _sendEnableStreamManagement() =>
      _connection.writeNonza(EnableNonza(_connection.account.smResumable));

  void _sendAckResponse() =>
      _connection.writeNonza(ANonza(streamState.lastReceivedStanza));

  void _tryToResumeStream() {
    if (!streamState.tryingToResume) {
      _connection.writeNonza(
          ResumeNonza(streamState.id!, streamState.lastReceivedStanza));
      streamState.tryingToResume = true;
    }
  }

  void _resumeState(Nonza resumedNonza) {
    streamState.tryingToResume = false;
    state = NegotiatorState.DONE_CLEAN_OTHERS;
    _connection.setState(XmppConnectionState.Resumed);
    _handleResumed(resumedNonza);
  }

  bool isResumeAvailable() => streamState.isResumeAvailable();

  void reset() {
    negotiatorStateStreamController = StreamController();
    backToIdle();
  }
}
