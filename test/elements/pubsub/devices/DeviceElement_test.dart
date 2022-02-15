import 'package:test/test.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DeviceElement.dart';

void main() {
  group('elements/pubsub/devices/DeviceElement.dart', () {
    test('Should test create element correctly with label', () {
      final deviceElement = DeviceElement.build(id: '123', label: 'Nokia 1');
      expect(deviceElement.name, 'device');
      expect(deviceElement.getAttribute('id')!.value, '123');
      expect(deviceElement.getAttribute('label')!.value, 'Nokia 1');
    });
    test('Should test create element correctly without label', () {
      final deviceElement = DeviceElement.build(id: '123');
      expect(deviceElement.name, 'device');
      expect(deviceElement.getAttribute('id')!.value, '123');
      expect(deviceElement.getAttribute('label') == null, true);
    });
  });
}
