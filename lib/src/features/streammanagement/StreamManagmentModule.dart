import 'dart:async';

import 'package:xmpp_stone/src/elements/nonzas/ANonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/EnableNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/EnabledNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/FailedNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/Nonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/RNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/ResumeNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/ResumedNonza.dart';
import 'package:xmpp_stone/src/elements/nonzas/SMNonza.dart';
import 'package:xmpp_stone/src/elements/stanzas/AbstractStanza.dart';
import 'package:xmpp_stone/src/features/streammanagement/StreamState.dart';

import '../../../xmpp_stone.dart';
import '../Negotiator.dart';

class StreamManagementModule extends Negotiator {

  static const TAG = 'StreamManagementModule';

  static Map<Connection, StreamManagementModule> instances =
      <Connection, StreamManagementModule>{};

  static StreamManagementModule getInstance(Connection connection) {
    var module = instances[connection];
    if (module == null) {
      module = StreamManagementModule(connection);
      instances[connection] = module;
    }
    return module;
  }

  StreamState streamState = StreamState();
  Connection _connection;
  StreamSubscription<AbstractStanza> inStanzaSubscription;
  StreamSubscription<AbstractStanza> outStanzaSubscription;
  StreamSubscription<XmppElement> inNonzaSubscription;

  bool ackTurnedOn = true;
  Timer timer;

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
          if (!_connection.isOpened() && timer != null) {timer.cancel();};
          if (state == XmppConnectionState.Closed) {
            streamState = StreamState();
            //state = XmppConnectionState.Idle;
          }
        });
  }

  @override
  List<XmppElement> match(List<XmppElement> requests) {
  var element = requests.firstWhere((request) => SMNonza.match(request), orElse: () => null);
  return element != null ? [element] : [];
  }

  //TODO: Improve
  @override
  void negotiate(List<XmppElement> elements) {
    if (elements != null && elements.isNotEmpty && SMNonza.match(elements[0]) && _connection.authenticated) {
      state = NegotiatorState.NEGOTIATING;
      inNonzaSubscription = _connection.inNonzasStream.listen(parseNonza);
      if (streamState.isResumeAvailable()) {
        tryToResumeStream();
      } else {
        sendEnableStreamManagement();
      }
    }
  }

  @override
  bool isReady() {
    return super.isReady() && (isResumeAvailable() || (_connection.fullJid.resource != null && _connection.fullJid.resource.isNotEmpty));
  }

  void parseNonza(XmppElement element) {
    if (state == NegotiatorState.NEGOTIATING) {
      if (EnabledNonza.match(element)) {
        handleEnabled(element);
      } else if (ResumedNonza.match(element)) {
        resumeState(element);
      } else if (FailedNonza.match(element)) {
        if (streamState.tryingToResume) {
          Log.d(TAG, 'Resuming failed');
          streamState = StreamState();
          state = NegotiatorState.DONE;
          negotiatorStateStreamController = StreamController();
          state = NegotiatorState.IDLE; //we will try again
        } else {
          Log.d(TAG, 'StreamManagmentFailed'); //try to send an error down to client
          state = NegotiatorState.DONE;
        }
      }
    } else if (state == NegotiatorState.DONE) {
      if (ANonza.match(element)) {
        parseAckResponse(element.getAttribute('h').value);
      } else if (RNonza.match(element)) {
        sendAckResponse();
      }
    }
  }

  void parseOutStanza(AbstractStanza stanza) {
    streamState.lastSentStanza++;
    streamState.nonConfirmedSentStanzas.addLast(stanza);
  }

  void parseInStanza(AbstractStanza stanza) {
    streamState.lastReceivedStanza++;
  }

  void handleEnabled(XmppElement element) {
    streamState.streamManagementEnabled = true;
    var resume = element.getAttribute('resume');
    if (resume != null && resume.value == 'true') {
      streamState.streamResumeEnabled = true;
      streamState.id = element.getAttribute('id').value;
    }
    state = NegotiatorState.DONE;
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer.periodic(
        Duration(milliseconds: 5000), (Timer t) => sendAckRequest());
    outStanzaSubscription = _connection.outStanzasStream.listen(parseOutStanza);
    inStanzaSubscription = _connection.inStanzasStream.listen(parseInStanza);
  }

  void handleResumed(XmppElement element) {
    parseAckResponse(element.getAttribute('h').value);

    state = NegotiatorState.DONE;
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer.periodic(
        Duration(milliseconds: 5000), (Timer t) => sendAckRequest());
  }

  void sendEnableStreamManagement() =>
      _connection.writeNonza(EnableNonza(true));

  void sendAckResponse() =>
      _connection.writeNonza(ANonza(streamState.lastReceivedStanza));

  void tryToResumeStream() {
    if(!streamState.tryingToResume) {
      _connection.writeNonza(
          ResumeNonza(streamState.id, streamState.lastReceivedStanza));
      streamState.tryingToResume = true;
    }
  }

  void resumeState(XmppElement resumedNonza) {
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
