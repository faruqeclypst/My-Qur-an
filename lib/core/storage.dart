// Penyimpanan lokal terpusat (shared_preferences).
// Di web, shared_preferences otomatis memakai localStorage. Tanpa backend.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  Storage._();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _db {
    final p = _prefs;
    if (p == null) throw StateError('Storage belum di-init');
    return p;
  }

  static String? getString(String key) => _db.getString(key);
  static Future<void> setString(String key, String value) =>
      _db.setString(key, value);

  static bool getBool(String key, [bool fallback = false]) =>
      _db.getBool(key) ?? fallback;
  static Future<void> setBool(String key, bool value) =>
      _db.setBool(key, value);

  static int getInt(String key, [int fallback = 0]) =>
      _db.getInt(key) ?? fallback;
  static Future<void> setInt(String key, int value) => _db.setInt(key, value);

  static double getDouble(String key, [double fallback = 0]) =>
      _db.getDouble(key) ?? fallback;
  static Future<void> setDouble(String key, double value) =>
      _db.setDouble(key, value);

  static List<String> getStringList(String key) =>
      _db.getStringList(key) ?? const [];
  static Future<void> setStringList(String key, List<String> value) =>
      _db.setStringList(key, value);

  static Future<void> remove(String key) => _db.remove(key);

  static Map<String, dynamic> getJson(String key) {
    final raw = _db.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) =>
      _db.setString(key, jsonEncode(value));
}
