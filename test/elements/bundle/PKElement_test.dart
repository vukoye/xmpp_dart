import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/bundles/PKElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/bundles/PKElement.dart', () {
    test('Should test create element correctly', () {
      final element = PKElement.build(id: '1', encodedData: 'encodedString');
      expect(element.name, 'pk');
      expect(element.getAttribute('id')!.value, '1');
      expect(element.textValue, 'encodedString');
    });
  });
}
