import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/bundles/SPKSElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/bundles/SPKSElement.dart', () {
    test('Should test create element correctly', () {
      final element = SPKSElement.build(encodedData: 'encodedString');
      expect(element.name, 'spks');
      expect(element.textValue, 'encodedString');
    });
  });
}
