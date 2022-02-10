import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/pubsub/PublishElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/pubsub/PublishElement.dart', () {
    test('Should test create element correctly', () {
      final publishElement = PublishElement.build('test-node');
      expect(publishElement.name, 'publish');
      expect(publishElement.getAttribute('node')!.value, 'test-node');
    });
    test('Should test create element correctly with omemo node', () {
      final publishElement = PublishElement.buildOMEMODevice();
      expect(publishElement.name, 'publish');
      expect(publishElement.getAttribute('node')!.value,
          'urn:xmpp:omemo:2:devices');
    });
  });
}
