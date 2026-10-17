/// Strict readers never echo server input in errors.
abstract final class JsonReader {
  static Map<String, dynamic> object(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException();
  }

  static String string(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw const FormatException();
  }

  static String? optionalString(dynamic value) =>
      value == null ? null : string(value);
  static int integer(dynamic value) {
    if (value is int) return value;
    throw const FormatException();
  }

  static double number(dynamic value) {
    if (value is num && value.isFinite) return value.toDouble();
    throw const FormatException();
  }

  static bool boolean(dynamic value) {
    if (value is bool) return value;
    throw const FormatException();
  }

  static List<T> list<T>(dynamic value, T Function(dynamic) read) {
    if (value is! List) throw const FormatException();
    return List<T>.unmodifiable(value.map(read));
  }

  static List<String> strings(dynamic value) => list(value, string);
  static DateTime date(dynamic value) => DateTime.parse(string(value));
  static T enumeration<T extends Enum>(dynamic value, List<T> choices) {
    final name = string(value);
    for (final choice in choices) {
      if (choice.name == name) return choice;
    }
    throw const FormatException();
  }
}
