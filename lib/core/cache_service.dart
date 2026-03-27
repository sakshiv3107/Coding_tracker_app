// lib/core/cache_service.dart
//
// Centralised disk-cache helper backed by SharedPreferences.
// Every entry stores:
//   - the JSON payload      (key: '<prefix><id>')
//   - a write timestamp ms  (key: '<prefix><id>_ts')
//
// Usage:
//   final json = await CacheService.read('lc_', username, maxAge: Duration(hours: 24));
//   await CacheService.write('lc_', username, jsonString);
//   await CacheService.invalidate('lc_', username);

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._(); // prevent instantiation

  // ── Read ─────────────────────────────────────────────────────────────────────
  /// Returns the cached JSON string if it exists and is younger than [maxAge].
  /// Returns null if the entry is missing, expired, or malformed.
  static Future<String?> read(
    String prefix,
    String id, {
    required Duration maxAge,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$prefix$id';
      final tsKey = '${key}_ts';

      final raw = prefs.getString(key);
      final tsMs = prefs.getInt(tsKey);

      if (raw == null || tsMs == null) return null;

      final age =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(tsMs));
      if (age > maxAge) {
        debugPrint('[Cache] $key expired (${age.inMinutes}m old)');
        return null;
      }

      debugPrint('[Cache] ✅ Hit: $key (${age.inMinutes}m old)');
      return raw;
    } catch (e) {
      debugPrint('[Cache] Read error for $prefix$id: $e');
      return null;
    }
  }

  // ── Write ────────────────────────────────────────────────────────────────────
  /// Persists [jsonString] to disk with the current timestamp.
  static Future<void> write(
    String prefix,
    String id,
    String jsonString,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$prefix$id';
      await prefs.setString(key, jsonString);
      await prefs.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
      debugPrint('[Cache] ✅ Wrote: $key');
    } catch (e) {
      debugPrint('[Cache] Write error for $prefix$id: $e');
    }
  }

  // ── Invalidate ───────────────────────────────────────────────────────────────
  /// Removes the cached entry (data + timestamp) for the given prefix+id.
  static Future<void> invalidate(String prefix, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$prefix$id';
      await prefs.remove(key);
      await prefs.remove('${key}_ts');
      debugPrint('[Cache] 🗑 Invalidated: $key');
    } catch (e) {
      debugPrint('[Cache] Invalidate error for $prefix$id: $e');
    }
  }

  // ── Clear all ─────────────────────────────────────────────────────────────────
  /// Removes ALL entries whose keys start with [prefix].
  static Future<void> clearPrefix(String prefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys()
          .where((k) => k.startsWith(prefix))
          .toList();
      for (final k in keysToRemove) {
        await prefs.remove(k);
      }
      debugPrint('[Cache] 🗑 Cleared all keys with prefix "$prefix"');
    } catch (e) {
      debugPrint('[Cache] clearPrefix error: $e');
    }
  }
}
