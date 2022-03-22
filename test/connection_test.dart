import 'dart:io';

import 'package:xmpp_stone/src/features/error/ConnectionStreamErrorHandler.dart';
import 'package:xmpp_stone/src/features/error/StreamConflictHandler.dart';
import 'package:xmpp_stone/xmpp_stone.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('connection.dart', () {
    group('handleResponse()', () {
      test('should handle conflict response', () {
        final accountSetting =
            XmppAccountSettings('Alice', 'alice', 'lit', 'foo', 5222);
        final connection = Connection(accountSetting);
        connection.connectionStreamErrorHandler =
            ConnectionStreamErrorHandler.init(connection);
        final conflictResponse =
            "<xmpp_stone><stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams'/><text xml:lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-streams'>Replaced by new connection</text></stream:error></xmpp_stone>";
        connection.handleResponse(conflictResponse);
        expect(1, 1);
      });
    });
  });
  // group('connection tests plain authentication', () {
  //   final firstResponse =
  //       """<?xml version='1.0'?><stream:stream id='5440668505555980289' version='1.0' xml:lang='en' xmlns:stream='http://etherx.jabber.org/streams' to='test@test.cp,' from='test.com' xmlns='jabber:client'><stream:features></stream:features></stream>""";
  //   final authResponse =
  //       '''<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">AHRlc3QAdGVzdA==</auth>''';
  //   final authenticating =
  //       """<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism><mechanism>SCRAM-SHA-1</mechanism><mechanism>X-OAUTH2</mechanism></mechanisms><register xmlns='http://jabber.org/features/iq-register'/></stream:features>""";
  //   final authenticationSuccessful =
  //       """<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>""";
  //   var firstCompleter = Completer();
  //   var secondCompleter = Completer();
  //   var fakeSocketStream =
  //       StreamController<String>.broadcast();
  //   test('test feature negotiation', () async {
  //     final mockSocket = MockSocket();
  //     final connection =
  //         Connection(XmppAccountSettings.fromJid('test@test.com', 'test'));
  //     connection.connectionStateStream.listen((state) {
  //       if (state == XmppConnectionState.DoneParsingFeatures) {
  //         if (!firstCompleter.isCompleted) firstCompleter.complete();
  //       } else if (state == XmppConnectionState.Authenticated) {
  //         secondCompleter.complete();
  //       }
  //     });
  //     connection.socket = mockSocket;
  //     when(mockSocket.write(authResponse)).thenAnswer((_) {
  //       fakeSocketStream.add(authenticationSuccessful);
  //     });
  //     fakeSocketStream.stream.listen(connection.handleResponse);
  //     fakeSocketStream.add(firstResponse);
  //     await firstCompleter.future;
  //     fakeSocketStream.add(authenticating);
  //     await secondCompleter.future;
  //   });
  // });
}
