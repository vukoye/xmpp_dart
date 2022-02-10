import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/bundles/IKElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/bundles/IKElement.dart', () {
    test('Should test create element correctly', () {
      final ikElement = IKElement.build(encodedData: 'encodedString');
      expect(ikElement.name, 'ik');
      expect(ikElement.textValue, 'encodedString');
    });
  });
}
