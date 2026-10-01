import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'fasting.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _y;
  late int _m;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar');
    final h = HijriCalendar.now();
    _y = h.hYear;
    _m = h.hMonth;
  }

  void _shift(int delta) {
    setState(() {
      _m += delta;
      if (_m > 12) {
        _m = 1;
        _y++;
      } else if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conv = HijriCalendar.now();
    final first = conv.hijriToGregorian(_y, _m, 1);
    final monthName = HijriCalendar.fromDate(first).longMonthName;
    final days = conv.getDaysInMonth(_y, _m);
    final offset = (first.weekday % 7 + 1) % 7;
    final today = DateTime.now();
    const wd = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    final cells = <Widget>[
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        Builder(builder: (_) {
          final g = conv.hijriToGregorian(_y, _m, d);
          final isToday = _same(g, today);
          final f = fastingFor(g);
          return Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isToday ? cs.primary : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(toArabicDigits(d),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isToday ? cs.onPrimary : cs.onSurface)),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: f == null
                      ? Colors.transparent
                      : (f.strong ? cs.tertiary : cs.primary.withOpacity(.45)),
                ),
              ),
            ]),
          );
        }),
    ];

    final events = <String>[];
    for (var d = 1; d <= days; d++) {
      final e = hijriEvents['$_m-$d'];
      if (e != null) events.add('${toArabicDigits(d)} $monthName: $e');
    }

    final upcoming = <MapEntry<DateTime, FastInfo>>[];
    for (var i = 0; i < 14; i++) {
      final g = today.add(Duration(days: i));
      final f = fastingFor(g);
      if (f != null) upcoming.add(MapEntry(g, f));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        AppCard(
          child: Column(children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(-1)),
              Expanded(
                child: Column(children: [
                  Text('$monthName ${toArabicDigits(_y)} هـ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(DateFormat('MMMM y', 'ar').format(first),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(1)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              for (final w in wd)
                Expanded(
                  child: Center(
                    child: Text(w, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ),
                ),
            ]),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 4, backgroundColor: cs.tertiary),
              const SizedBox(width: 6),
              const Text('صيام مؤكد', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 16),
              CircleAvatar(radius: 4, backgroundColor: cs.primary.withOpacity(.45)),
              const SizedBox(width: 6),
              const Text('اثنين / خميس', style: TextStyle(fontSize: 11)),
            ]),
          ]),
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('مناسبات الشهر', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final e in events)
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e)),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        const Text('الصيام المستحب القادم',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final u in upcoming)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.no_food_outlined, color: u.value.strong ? cs.tertiary : cs.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(u.value.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(DateFormat('EEEE d MMM', 'ar').format(u.key),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        Text('التاريخ الهجري محسوب فلكيًا وقد يختلف يومًا عن رؤية الهلال في بلدك.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}
