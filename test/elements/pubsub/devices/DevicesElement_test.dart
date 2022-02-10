import 'package:test/test.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DeviceElement.dart';
import 'package:xmpp_stone/src/elements/pubsub/devices/DevicesElement.dart';

void main() {
  group('elements/pubsub/devices/devicesElement.dart', () {
    test('Should test create element correctly', () {
      final devicesElement = DevicesElement.build([]);
      expect(devicesElement.name, 'devices');
      expect(devicesElement.getAttribute('xmlns')!.value, 'urn:xmpp:omemo:2');
    });
    test('Should test create element correctly with devices', () {
      final device1 = DeviceElement.build(id: '1', label: 'Nokia');
      final device2 = DeviceElement.build(id: '2', label: 'Pinephone');
      final devicesElement = DevicesElement.build([device1, device2]);
      expect(devicesElement.name, 'devices');
      expect(devicesElement.getAttribute('xmlns')!.value, 'urn:xmpp:omemo:2');
      expect(devicesElement.children.length, 2);
      final parsedDeviceList = DeviceElement.parse(devicesElement);
      expect(parsedDeviceList[0]!.getAttribute('id')!.value, '1');
      expect(parsedDeviceList[1]!.getAttribute('id')!.value, '2');
    });
  });
}
