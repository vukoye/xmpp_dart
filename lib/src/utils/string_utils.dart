import 'package:collection/collection.dart';

extension EnumParser on String {
  T? toEnum<T>(List<T> values) {
    return values.firstWhereOrNull((e) =>
    e.toString().toLowerCase().split('.').last == '$this'.toLowerCase());
  }
}