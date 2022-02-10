import 'dart:io';

import 'package:xmpp_stone/src/elements/pubsub/PubSubElement.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/pubsub/PubSubElement.dart', () {
    test('Should test create element correctly', () {
      final pubsubElement = PubSubElement.build();
      expect(pubsubElement.name, 'pubsub');
      expect(pubsubElement.getAttribute('xmlns')!.value,
          'http://jabber.org/protocol/pubsub');
    });
  });
}
