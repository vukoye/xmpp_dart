import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;

var multipleroots = """
<id>d</id><id>d</id>
""";

void main() {
  group('xml test', () {
    test('strange_error', () {
      var xmlResponse = xml.parse("<a>$multipleroots</a>");
      print(xmlResponse.toXmlString());
    });
  });
}
