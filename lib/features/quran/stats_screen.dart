import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_providers.dart';

class QuranStatsScreen extends ConsumerWidget {
  const QuranStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final stats = ref.watch(quranStatsProvider);
    final now = DateTime.now();
    final total = stats.values.fold<int>(0, (a, b) => a + b);
    final today = stats[dayKey(now)] ?? 0;
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return MapEntry(d, stats[dayKey(d)] ?? 0);
    });
    final maxV = last7.map((e) => e.value).fold<int>(1, (a, b) => b > a ? b : a);

    var streak = 0;
    var d = (stats[dayKey(now)] ?? 0) > 0 ? now : now.subtract(const Duration(days: 1));
    while ((stats[dayKey(d)] ?? 0) > 0) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }

    Widget tile(String label, String value) => Expanded(
          child: AppCard(
            child: Column(children: [
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات القراءة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            tile('آيات اليوم', toArabicDigits(today)),
            const SizedBox(width: 8),
            tile('أيام متتالية', toArabicDigits(streak)),
            const SizedBox(width: 8),
            tile('إجمالي الآيات', toArabicDigits(total)),
          ]),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('آخر ٧ أيام', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final e in last7)
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('${e.value}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          height: 4 + 70 * e.value / maxV,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: e.value > 0 ? cs.primary : cs.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(DateFormat('E', 'ar').format(e.key),
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              'مجموع ما قرأت يعادل ${(total / 6236 * 100).toStringAsFixed(1)}٪ من القرآن الكريم (٦٢٣٦ آية).',
            ),
          ),
        ],
      ),
    );
  }
}
