import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptoutils/utils.dart';
import 'package:xmpp_stone/src/features/sasl/ScramSha1SaslHandler.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:xml/xml.dart' as xml;

var multipleroots = """
<id>d</id><id>d</id>
""";


void main() {
  group('xml test', () {
    test('strange_error', ()  {
      var xmlResponse = xml.parse("<a>$multipleroots</a>");
      print(xmlResponse.toXmlString());
    });

  });
}