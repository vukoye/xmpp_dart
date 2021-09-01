import 'package:test/test.dart';
import 'package:xmpp_stone/src/data/Jid.dart';

void main() {
  group('JID parsing tests', () {
   test('Test complex JID', () {
     var fullJid = 'local-part@test.example.com/flutter-EC24A060-504C-E974-CE60-06D360D7C36F';
     var jid = Jid.fromFullJid(fullJid);

     expect(jid.local, isNotEmpty);
     expect(jid.domain, isNotEmpty);
     expect(jid.resource, isNotEmpty);
   });
   test('Test short JID', () {
     var fullJid = 'local-part@test.example.com';
     var jid = Jid.fromFullJid(fullJid);

     expect(jid.local, isNotEmpty);
     expect(jid.domain, isNotEmpty);
     expect(jid.resource, isNull);
   });
   test('Test JID without \'local\' part', () {
     var fullJid = 'test.example.com/flutter-EC24A060-504C-E974-CE60-06D360D7C36F';
     var jid = Jid.fromFullJid(fullJid);

     expect(jid.local, isEmpty);
     expect(jid.domain, isNotEmpty);
     expect(jid.resource, isNotEmpty);
   });

   test('Test JID without \'domain\' part', () {
     var fullJid = 'local-part@/flutter-EC24A060-504C-E974-CE60-06D360D7C36F';
     var jid = Jid.fromFullJid(fullJid);

     //not valid JID without domain
     expect(jid.local, isEmpty);
     expect(jid.domain, isEmpty);
     expect(jid.resource, isEmpty);
   });
  });
}