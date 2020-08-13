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

class StreamManagementModule extends ConnectionNegotiator {
  static Map<Connection, StreamManagementModule> instances =
      Map<Connection, StreamManagementModule>();

  static StreamManagementModule getInstance(Connection connection) {
    StreamManagementModule module = instances[connection];
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
  StreamSubscription<Nonza> inNonzaSubscription;

  bool ackTurnedOn = true;
  Timer timer;

  StreamController<AbstractStanza> _deliveredStanzasStreamController =
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
        print("Delivered: " + stanza.id);
      } else {
        print("Delivered stanza without id " + stanza.name);
      }
    }
  }

  StreamManagementModule(Connection connection) {
    _connection = connection;
    _connection.streamManagementModule = this;
    ackTurnedOn = connection.account.ackEnabled;
    _connection.connectionStateStream.listen((state) => {
          if (state == XmppConnectionState.Reconnecting)
            {negotiatorStateStreamController = StreamController()},
          if (!_connection.isOpened() && timer != null) {timer.cancel()},
          if (state == XmppConnectionState.Closed) {streamState = StreamState()}
        });
  }

  @override
  bool match(Nonza request) {
    return SMNonza.match(request);
  }

  @override
  void negotiate(Nonza nonza) {
    if (SMNonza.match(nonza) && _connection.authenticated) {
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
    return super.isReady() && (isResumeAvailable() || _connection.fullJid.resource.isNotEmpty);
  }

  void parseNonza(Nonza nonza) {
    if (state == NegotiatorState.NEGOTIATING) {
      if (EnabledNonza.match(nonza)) {
        handleEnabled(nonza);
      } else if (ResumedNonza.match(nonza)) {
        resumeState(nonza);
      } else if (FailedNonza.match(nonza)) {
        if (streamState.tryingToResume) {
          print("Resuming failed");
          streamState = StreamState();
          state = NegotiatorState.DONE;
          negotiatorStateStreamController = StreamController();
          state = NegotiatorState.IDLE; //we will try again
        } else {
          print("StreamManagmentFailed"); //try to send an error down to client
          state = NegotiatorState.DONE;
        }
      }
    } else if (state == NegotiatorState.DONE) {
      if (ANonza.match(nonza)) {
        parseAckResponse(nonza.getAttribute('h').value);
      } else if (RNonza.match(nonza)) {
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

  void handleEnabled(Nonza nonza) {
    streamState.streamManagementEnabled = true;
    var resume = nonza.getAttribute('resume');
    if (resume != null && resume.value == 'true') {
      streamState.streamResumeEnabled = true;
      streamState.id = nonza.getAttribute('id').value;
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

  void sendEnableStreamManagement() =>
      _connection.writeNonza(EnableNonza(true));

  void sendAckResponse() =>
      _connection.writeNonza(ANonza(streamState.lastReceivedStanza));

  void tryToResumeStream() {
    _connection.writeNonza(
        ResumeNonza(streamState.id, streamState.lastReceivedStanza));
    streamState.tryingToResume = true;
  }

  void resumeState(Nonza resumedNonza) {
    state = NegotiatorState.DONE_CLEAN_OTHERS;
    parseAckResponse(resumedNonza.getAttribute('h').value);
    _connection.setState(XmppConnectionState.Resumed);
  }

  bool isResumeAvailable() => streamState.isResumeAvailable();
}
