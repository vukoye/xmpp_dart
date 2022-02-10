import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/bundles/BundleElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/bundles/BundleElement.dart', () {
    test('Should test create element correctly', () {
      final bundleElement = BundleElement.build('test-node');
      expect(bundleElement.name, 'bundle');
      expect(bundleElement.getAttribute('xmlns')!.value, 'test-node');
    });
    test('Should test create element correctly with omemo', () {
      final bundleElement = BundleElement.buildOMEMOBundle();
      expect(bundleElement.name, 'bundle');
      expect(bundleElement.getAttribute('xmlns')!.value, 'urn:xmpp:omemo:2');
    });
  });
}
