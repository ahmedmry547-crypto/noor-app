import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils.dart';

final azkarCounterProvider =
    NotifierProvider<AzkarCounters, Map<String, int>>(AzkarCounters.new);

class AzkarCounters extends Notifier<Map<String, int>> {
  String get _key => 'azkar_${dayKey(DateTime.now())}';

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

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(state));
  }

  void tap(String key, int max) {
    final cur = state[key] ?? 0;
    if (cur >= max) return;
    state = {...state, key: cur + 1};
    _save();
  }

  void resetCategory(int cat) {
    state = Map.of(state)..removeWhere((k, _) => k.startsWith('${cat}_'));
    _save();
  }
}
