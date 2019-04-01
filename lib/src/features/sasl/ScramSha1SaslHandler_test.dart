import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptoutils/utils.dart';
import 'package:xmppstone/src/features/sasl/ScramSha1SaslHandler.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('ScramSaslTests', () {
    test('sasl escape test', ()  {
      expect(ScramSaslHandler.saslEscape("test=test,test"), "test=2Ctest=3Dtest");
    });
    test('additional test', () {
      var key2 = hmac(utf8.encode("pencil"), base64.decode('QSXCR+Q6sek8bf92') + [0,0,0,1]);
      print(key2);
      //var key = pb.generateKey("pencil", utf8.decode(base64.decode('QSXCR+Q6sek8bf92')), 4096, 8);
    });
  });
}

List<int> hmac(List<int> key, List<int> input) {
  var hmac = Hmac(sha1, key);
  return hmac.convert(input).bytes;
}