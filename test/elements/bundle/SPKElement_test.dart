import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/bundles/SPKElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/bundles/SPKElement.dart', () {
    test('Should test create element correctly', () {
      final element = SPKElement.build(id: '1', encodedData: 'encodedString');
      expect(element.name, 'spk');
      expect(element.getAttribute('id')!.value, '1');
      expect(element.textValue, 'encodedString');
    });
  });
}
