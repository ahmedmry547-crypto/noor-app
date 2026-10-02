import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils.dart';

export 'quran_api.dart' show quranDataProvider;

final quranFontSizeProvider = StateProvider<double>((ref) => 28);
final tajweedOnProvider = StateProvider<bool>((ref) => true);

/// true = whole Mushaf page fits on screen; false = bigger text, scrollable.
final quranFitProvider = StateProvider<bool>((ref) => true);

/// verses read per day: { "2026-9-30": 42 }
final quranStatsProvider =
    NotifierProvider<QuranStats, Map<String, int>>(QuranStats.new);

class QuranStats extends Notifier<Map<String, int>> {
  static const _key = 'quran_stats';

  @override
  Map<String, int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s != null) {
      state = (jsonDecode(s) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    }
  }

  Future<void> addRead(int verses) async {
    final k = dayKey(DateTime.now());
    state = {...state, k: (state[k] ?? 0) + verses};
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(state));
  }
}
