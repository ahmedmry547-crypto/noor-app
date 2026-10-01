import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/data/prayer_providers.dart';

class QiyamInfo {
  QiyamInfo(this.nightStart, this.nightEnd);
  final DateTime nightStart;
  final DateTime nightEnd;
  Duration get length => nightEnd.difference(nightStart);
  DateTime get midnight => nightStart.add(length ~/ 2);
  DateTime get lastThirdStart => nightEnd.subtract(length ~/ 3);
}

QiyamInfo computeQiyam(PrayerDay day, DateTime now) {
  final maghrib = day.today.firstWhere((e) => e.key == Prayer.maghrib).value;
  final fajr = day.today.firstWhere((e) => e.key == Prayer.fajr).value;
  if (now.isBefore(fajr)) {
    return QiyamInfo(maghrib.subtract(const Duration(days: 1)), fajr);
  }
  return QiyamInfo(maghrib, day.tomorrowFajr);
}

class QiyamEntry {
  QiyamEntry(this.date, this.minutes, this.rakaat, this.read);
  final DateTime date;
  final int minutes;
  final int rakaat;
  final String read;

  Map<String, dynamic> toJson() =>
      {'d': date.toIso8601String(), 'm': minutes, 'r': rakaat, 'q': read};
  factory QiyamEntry.fromJson(Map<String, dynamic> j) => QiyamEntry(
      DateTime.parse(j['d'] as String), j['m'] as int, j['r'] as int, j['q'] as String);
}

final qiyamStartProvider = StateProvider<DateTime?>((ref) => null);

final qiyamLogProvider = NotifierProvider<QiyamLog, List<QiyamEntry>>(QiyamLog.new);

class QiyamLog extends Notifier<List<QiyamEntry>> {
  static const _key = 'qiyam_log';

  @override
  List<QiyamEntry> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s != null) {
      state = (jsonDecode(s) as List)
          .map((e) => QiyamEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> add(QiyamEntry e) async {
    state = [e, ...state];
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}
