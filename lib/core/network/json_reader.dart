import '../domain/page.dart';

/// Strict readers never echo server input in errors.
abstract final class JsonReader {
  static Page<T> page<T>(Map<String, dynamic> json, T Function(dynamic) read) {
    final items = list(json['items'], read);
    final total = integer(json['total']),
        limit = integer(json['limit']),
        offset = integer(json['offset']);
    if (total < 0 || limit < 1 || offset < 0 || items.length > limit)
      throw const FormatException();
    return Page(items: items, total: total, limit: limit, offset: offset);
  }

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
