import 'package:hijri/hijri_calendar.dart';

class FastInfo {
  const FastInfo(this.label, this.strong);
  final String label;
  final bool strong;
}

FastInfo? fastingFor(DateTime g) {
  final h = HijriCalendar.fromDate(g);
  final m = h.hMonth, d = h.hDay;
  if (m == 9) return null;
  if (m == 10 && d == 1) return null;
  if (m == 12 && d >= 10 && d <= 13) return null;
  if (m == 12 && d == 9) return const FastInfo('يوم عرفة', true);
  if (m == 1 && d == 10) return const FastInfo('يوم عاشوراء', true);
  if (m == 1 && d == 9) return const FastInfo('تاسوعاء', true);
  if (d >= 13 && d <= 15) return const FastInfo('الأيام البيض', true);
  if (g.weekday == DateTime.monday) return const FastInfo('الاثنين', false);
  if (g.weekday == DateTime.thursday) return const FastInfo('الخميس', false);
  return null;
}

const hijriEvents = <String, String>{
  '1-1': 'رأس السنة الهجرية',
  '1-10': 'يوم عاشوراء',
  '9-1': 'بداية شهر رمضان',
  '9-27': 'ليلة السابع والعشرين (من الليالي الوترية)',
  '10-1': 'عيد الفطر',
  '12-9': 'يوم عرفة',
  '12-10': 'عيد الأضحى',
};
