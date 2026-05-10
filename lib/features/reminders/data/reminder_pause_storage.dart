import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists reminder ids the user paused locally (alarm cancelled until resumed).
class ReminderPauseStorage {
  ReminderPauseStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'reminder_paused_ids_json';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<Set<String>> loadPausedIds() async {
    final p = await _ensure();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> savePausedIds(Set<String> ids) async {
    final p = await _ensure();
    await p.setString(_key, jsonEncode(ids.toList()));
  }

  Future<void> pause(String id) async {
    final s = await loadPausedIds();
    s.add(id);
    await savePausedIds(s);
  }

  Future<void> resume(String id) async {
    final s = await loadPausedIds();
    s.remove(id);
    await savePausedIds(s);
  }
}
