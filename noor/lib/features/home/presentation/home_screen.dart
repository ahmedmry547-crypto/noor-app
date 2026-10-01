import 'dart:ui' show FontFeature;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../data/prayer_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('نور'),
        actions: [
          Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
          Switch(
            value: isDark,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setDark(v),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          _DateHeader(),
          SizedBox(height: 12),
          _NextPrayerCard(),
          SizedBox(height: 12),
          _PrayerTimesRow(),
          SizedBox(height: 16),
          _AzkarCards(),
          SizedBox(height: 16),
          _TrackerCard(),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader();
  @override
  Widget build(BuildContext context) {
    HijriCalendar.setLocal('ar');
    final h = HijriCalendar.now();
    final g = DateFormat('EEEE d MMMM', 'ar').format(DateTime.now());
    return Text('${h.hDay} ${h.longMonthName} ${h.hYear} هـ  •  $g',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant));
  }
}

class _NextPrayerCard extends ConsumerWidget {
  const _NextPrayerCard();

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final day = ref.watch(prayerDayProvider);
    final now = ref.watch(tickerProvider).value ?? DateTime.now();

    return AppCard(
      color: cs.primary,
      padding: const EdgeInsets.all(24),
      child: day.when(
        loading: () => SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator(color: cs.onPrimary))),
        error: (e, _) => Text('تعذّر حساب المواقيت', style: TextStyle(color: cs.onPrimary)),
        data: (d) {
          final n = d.next(now);
          final left = n.value.difference(now);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الصلاة القادمة', style: TextStyle(color: cs.onPrimary.withOpacity(.8))),
              const SizedBox(height: 4),
              Text(prayerNamesAr[n.key]!,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: cs.onPrimary)),
              const SizedBox(height: 12),
              Text(_fmt(left.isNegative ? Duration.zero : left),
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text('الساعة ${DateFormat('h:mm a', 'ar').format(n.value)}',
                  style: TextStyle(color: cs.onPrimary.withOpacity(.8))),
            ],
          );
        },
      ),
    );
  }
}

class _PrayerTimesRow extends ConsumerWidget {
  const _PrayerTimesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final day = ref.watch(prayerDayProvider).value;
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    if (day == null) return const SizedBox.shrink();
    final nextKey = day.next(now).key;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          for (final e in day.today)
            Expanded(
              child: Column(
                children: [
                  Text(prayerNamesAr[e.key]!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: e.key == nextKey ? FontWeight.w800 : FontWeight.w500,
                          color: e.key == nextKey ? cs.primary : cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(DateFormat('h:mm', 'ar').format(e.value),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: e.key == nextKey ? cs.primary : cs.onSurface)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AzkarCards extends StatelessWidget {
  const _AzkarCards();

  @override
  Widget build(BuildContext context) {
    final isMorning = DateTime.now().hour < 15;
    return Row(
      children: [
        Expanded(child: _AzkarTile('أذكار الصباح', Icons.wb_sunny_rounded, isMorning, 0)),
        const SizedBox(width: 12),
        Expanded(child: _AzkarTile('أذكار المساء', Icons.nights_stay_rounded, !isMorning, 1)),
      ],
    );
  }
}

class _AzkarTile extends ConsumerWidget {
  const _AzkarTile(this.title, this.icon, this.highlight, this.category);
  final String title;
  final IconData icon;
  final bool highlight;
  final int category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        ref.read(azkarCategoryProvider.notifier).state = category;
        ref.read(tabIndexProvider.notifier).state = 2;
      },
      child: AppCard(
        color: highlight ? cs.primaryContainer : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TrackerCard extends ConsumerWidget {
  const _TrackerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final done = ref.watch(trackerProvider);
    final progress = done.length / trackerItems.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('عبادات اليوم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${done.length}/${trackerItems.length}',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: 8),
          for (final e in trackerItems.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: done.contains(e.key),
              title: Text(e.value),
              onChanged: (_) => ref.read(trackerProvider.notifier).toggle(e.key),
            ),
        ],
      ),
    );
  }
}
