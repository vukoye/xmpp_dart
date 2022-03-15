import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xmpp_stone/src/elements/encryption/EncryptElement.dart';
import 'package:xmpp_stone/src/parser/StanzaParser.dart';

void main() {
  group('elements/encryption/EncryptElement.dart', () {
    test('Should parse encrypt element correctly', () {
      final xmlDoc = XmlDocument.parse(
          """<message id="ac0fdeb0-93ce-11ec-a6de-198322437fd4" type="chat" to="627075027401@staging.xmpp.hiapp-chat.com" from="627775027401@staging.xmpp.hiapp-chat.com/Android-9bbd97e55c84849a-2a4866b1-1a67-4377-9367-50e9111a80d7">
        <encrypted xmlns="urn:xmpp:omemo:2">
          <header sid="9bbd97e55c84849a">
            <keys jid="627075027401@staging.xmpp.hiapp-chat.com">
              <key rid="96F42D78-D7E7-4DFD-ADE8-4A08CE64836D" kex="true">Mwi9YxABGiApYztg3BqMvJhYG0+g9XooxYoPSmLyKYdpjFILoBAQDiIg7E0hQWjFnmpn6VKQVwLILGK6LkQm6ohGz6JzfgtGvlEqggMzCAAQABogrmdT3ichMTqyV3ypaBHnp3/EjEsHp/RlKkhaWdFOZwMi0AIewOMkYcEiKUhUKCZAhkHOovfU37VSNfbZpUQb0lmuFNoH3F9cwbquAMmnL2VKiu2p06Ajk6Ejg6ykX9N446kP89vVcSBSA5rHgUca0i7PM1907pMf/TIh9HbcQ5Sq1IevFnIBJNctjCKEph290qV9zpHtLc+YUj2dhBpfeJLkjmMIWiRXFvWqjxXTefHHt6ENKMyNaCUer2vPKgBDeBrzM4lcTOZ1dFyfafd6jOzcuc/aXlt9qUXf9+DJRbX0cA1i0Gu68TkCL09Uw8tg6990cJkgkYZp5SXyZ28w7KOfoJFdwltTXW2VeYmk5RyEM/rq/OhSiJbGd0VOX6alt8jN6JcCOyxufE21hSX6An2Fg/ufowROPAtuBOm1wqTCAyH4HkTO3plQgokr2AC3Jjr4f7KBoqMyVFKgcdUfcAdYYIfu+CiEFlGbs1N3yB12VjImcpkrtnQPHzIgDJzArQt3jq8ut1hylJrxFJ1Qc0jt05pXTUME12bHBJk=</key>
            </keys>
          </header>
          <payload></payload>
        </encrypted>
        <request xmlns="urn:xmpp:receipts"/>
      </message>
""");

      final stanza = StanzaParser.parseStanza(xmlDoc.rootElement);
      final encryptedMessage = EncryptElement.parseElement(stanza);
      print(encryptedMessage!.buildXmlString());
      expect(encryptedMessage != null, true);
      expect(encryptedMessage.buildXmlString(),
          """<encrypted xmlns="urn:xmpp:omemo:2">
  <header sid="9bbd97e55c84849a">
    <keys jid="627075027401@staging.xmpp.hiapp-chat.com">
      <key rid="96F42D78-D7E7-4DFD-ADE8-4A08CE64836D" kex="true">Mwi9YxABGiApYztg3BqMvJhYG0+g9XooxYoPSmLyKYdpjFILoBAQDiIg7E0hQWjFnmpn6VKQVwLILGK6LkQm6ohGz6JzfgtGvlEqggMzCAAQABogrmdT3ichMTqyV3ypaBHnp3/EjEsHp/RlKkhaWdFOZwMi0AIewOMkYcEiKUhUKCZAhkHOovfU37VSNfbZpUQb0lmuFNoH3F9cwbquAMmnL2VKiu2p06Ajk6Ejg6ykX9N446kP89vVcSBSA5rHgUca0i7PM1907pMf/TIh9HbcQ5Sq1IevFnIBJNctjCKEph290qV9zpHtLc+YUj2dhBpfeJLkjmMIWiRXFvWqjxXTefHHt6ENKMyNaCUer2vPKgBDeBrzM4lcTOZ1dFyfafd6jOzcuc/aXlt9qUXf9+DJRbX0cA1i0Gu68TkCL09Uw8tg6990cJkgkYZp5SXyZ28w7KOfoJFdwltTXW2VeYmk5RyEM/rq/OhSiJbGd0VOX6alt8jN6JcCOyxufE21hSX6An2Fg/ufowROPAtuBOm1wqTCAyH4HkTO3plQgokr2AC3Jjr4f7KBoqMyVFKgcdUfcAdYYIfu+CiEFlGbs1N3yB12VjImcpkrtnQPHzIgDJzArQt3jq8ut1hylJrxFJ1Qc0jt05pXTUME12bHBJk=</key>
    </keys>
  </header>
  <payload></payload>
</encrypted>""");
    });
  });
}
