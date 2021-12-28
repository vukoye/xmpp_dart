import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:xmpp_stone/src/features/sasl/ScramSaslHandler.dart';
import 'package:test/test.dart';

void main() {
  group('ScramSaslTests', () {
    test('sasl escape test', () {
      expect(
          ScramSaslHandler.saslEscape('test=test,test'), 'test=2Ctest=3Dtest');
    });
    test('S1', () {
      var hmacValue = hmac(utf8.encode('urmasica'), 'bV5mZvHe+RNoeL537h5RSQ==');
      print('hmac: $hmacValue');
    });
  });
}

List<int> hmac(List<int> key, String input) {
  var hmac = Hmac(sha1, key);
  return hmac.convert(utf8.encode(input) + [0, 0, 0, 1]).bytes;
}
