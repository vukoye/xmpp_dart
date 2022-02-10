import 'dart:io';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xmpp_stone/src/elements/pubsub/PublishOptionsElement.dart';

class MockSocket extends Mock implements Socket {}

void main() {
  group('elements/pubsub/PublishOptionsElement.dart', () {
    test('Should test create element correctly with acccess model', () {
      final publishElement = PublishOptionsElement.build(accessModel: 'open');
      expect(publishElement.name, 'publish-options');
      print(publishElement.buildXmlString());
      expect(publishElement.getChild('x') != null, true);
      expect(publishElement.buildXmlString(), """<publish-options>
  <x xmlns="jabber:x:data" type="submit">
    <field var="FORM_TYPE" type="hidden">
      <value>http://jabber.org/protocol/pubsub#publish-options</value>
    </field>
    <field var="pubsub#access_model">
      <value>open</value>
    </field>
  </x>
</publish-options>""");
    });
    test('Should test create element correctly with max item', () {
      final publishElement = PublishOptionsElement.build(maxItems: 'max');
      expect(publishElement.name, 'publish-options');
      print(publishElement.buildXmlString());
      expect(publishElement.getChild('x') != null, true);
      expect(publishElement.buildXmlString(), """<publish-options>
  <x xmlns="jabber:x:data" type="submit">
    <field var="FORM_TYPE" type="hidden">
      <value>http://jabber.org/protocol/pubsub#publish-options</value>
    </field>
    <field var="pubsub#max_items">
      <value>max</value>
    </field>
  </x>
</publish-options>""");
    });
  });
}
