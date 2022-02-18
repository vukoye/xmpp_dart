import 'package:test/test.dart';
import 'package:xmpp_stone/src/elements/bundles/PKElement.dart';
import 'package:xmpp_stone/src/elements/bundles/PreKeysElement.dart';

void main() {
  group('elements/bundles/PreKeysElement.dart', () {
    test('Should test create element correctly', () {
      final pk = PKElement.build(id: '1', encodedData: 'encodedString');
      final preKey = PreKeysElement.build(pkElements: [pk]);
      expect(preKey.name, 'prekeys');
      expect(preKey.children.isNotEmpty, true);
      expect(preKey.children.first!.name, 'pk');
      expect(preKey.children.first!.getAttribute('id')!.value, '1');
      expect(preKey.children.first!.textValue, 'encodedString');
    });
  });
}
