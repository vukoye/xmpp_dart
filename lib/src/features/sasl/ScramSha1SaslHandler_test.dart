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
    test('S1', () {
      var salt = "bV5mZvHe+RNoeL537h5RSQ==";
      var hmacValue = hmac(utf8.encode("urmasica"), "bV5mZvHe+RNoeL537h5RSQ==");
      var a = CryptoUtils.bytesToBase64(utf8.encode("n,,"), false, false);
      print("hmac: $hmacValue");
    });
  });
}



List<int> hmac(List<int> key, String input) {

  var hmac = Hmac(sha1, key);
  return hmac.convert(utf8.encode(input) + [0,0,0,1]).bytes;
}