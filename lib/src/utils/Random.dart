import 'dart:math';

String generateId() {
  const ASCII_START = 65;
  const ASCII_END = 90;
  var codeUnits = List.generate(9, (index) {
    return Random.secure().nextInt(ASCII_END - ASCII_START) + ASCII_START;
  });
  return String.fromCharCodes(codeUnits);
}
