import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const prayerNamesAr = {
  Prayer.fajr: 'الفجر',
  Prayer.sunrise: 'الشروق',
  Prayer.dhuhr: 'الظهر',
  Prayer.asr: 'العصر',
  Prayer.maghrib: 'المغرب',
  Prayer.isha: 'العشاء',
};

class PrayerDay {
  PrayerDay(this.today, this.tomorrowFajr);
  final List<MapEntry<Prayer, DateTime>> today;
  final DateTime tomorrowFajr;

  MapEntry<Prayer, DateTime> next(DateTime now) {
    for (final e in today) {
      if (e.value.isAfter(now)) return e;
    }
    return MapEntry(Prayer.fajr, tomorrowFajr);
  }
}

/// Falls back to Cairo if location is unavailable/denied.
Future<Coordinates> _coords() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) throw 'off';
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) throw 'denied';
    final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
    return Coordinates(p.latitude, p.longitude);
  } catch (_) {
    return Coordinates(30.0444, 31.2357);
  }
}

final prayerDayProvider = FutureProvider<PrayerDay>((ref) async {
  final c = await _coords();
  final params = CalculationMethod.egyptian.getParameters()..madhab = Madhab.shafi;
  final now = DateTime.now();
  final t = PrayerTimes(c, DateComponents.from(now), params);
  final tm = PrayerTimes(c, DateComponents.from(now.add(const Duration(days: 1))), params);
  return PrayerDay([
    MapEntry(Prayer.fajr, t.fajr.toLocal()),
    MapEntry(Prayer.sunrise, t.sunrise.toLocal()),
    MapEntry(Prayer.dhuhr, t.dhuhr.toLocal()),
    MapEntry(Prayer.asr, t.asr.toLocal()),
    MapEntry(Prayer.maghrib, t.maghrib.toLocal()),
    MapEntry(Prayer.isha, t.isha.toLocal()),
  ], tm.fajr.toLocal());
});

/// Emits current time every second (drives the countdown).
final tickerProvider = StreamProvider<DateTime>(
    (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));

// ---------- Daily worship tracker ----------
const trackerItems = {
  'fajr': 'صلاة الفجر',
  'dhuhr': 'صلاة الظهر',
  'asr': 'صلاة العصر',
  'maghrib': 'صلاة المغرب',
  'isha': 'صلاة العشاء',
  'morning': 'أذكار الصباح',
  'evening': 'أذكار المساء',
  'wird': 'الورد اليومي من القرآن',
};

final trackerProvider =
    NotifierProvider<TrackerNotifier, Set<String>>(TrackerNotifier.new);

class TrackerNotifier extends Notifier<Set<String>> {
  String get _key {
    final d = DateTime.now();
    return 'tracker_${d.year}-${d.month}-${d.day}'; // resets each day
  }

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = (p.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String id) async {
    final s = {...state};
    s.contains(id) ? s.remove(id) : s.add(id);
    state = s;
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, s.toList());
  }
}
