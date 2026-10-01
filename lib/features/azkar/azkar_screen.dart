import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../home/data/prayer_providers.dart';
import 'azkar_data.dart';
import 'azkar_provider.dart';

class AzkarScreen extends ConsumerWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cat = ref.watch(azkarCategoryProvider);
    final counters = ref.watch(azkarCounterProvider);
    final items = azkarData[cat];

    void onTap(int i) {
      final z = items[i];
      final key = '${cat}_$i';
      final cur = counters[key] ?? 0;
      if (cur >= z.count) return;
      HapticFeedback.lightImpact();
      ref.read(azkarCounterProvider.notifier).tap(key, z.count);

      final after = {...counters, key: cur + 1};
      final done = List.generate(items.length, (j) => (after['${cat}_$j'] ?? 0) >= items[j].count)
          .every((e) => e);
      if (done) {
        HapticFeedback.mediumImpact();
        final id = cat == 0 ? 'morning' : (cat == 1 ? 'evening' : null);
        if (id != null && !ref.read(trackerProvider).contains(id)) {
          ref.read(trackerProvider.notifier).toggle(id);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار والأدعية'),
        actions: [
          IconButton(
            tooltip: 'إعادة العدّ',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => ref.read(azkarCounterProvider.notifier).resetCategory(cat),
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: azkarTitles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(azkarTitles[i]),
              selected: cat == i,
              onSelected: (_) => ref.read(azkarCategoryProvider.notifier).state = i,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final z = items[i];
              final cur = counters['${cat}_$i'] ?? 0;
              final finished = cur >= z.count;
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onTap(i),
                child: Opacity(
                  opacity: finished ? 0.5 : 1,
                  child: AppCard(
                    child: Column(children: [
                      Text(z.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, height: 2.0)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: finished ? cs.primary : cs.primaryContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: finished
                            ? Icon(Icons.check, color: cs.onPrimary, size: 20)
                            : Text('${toArabicDigits(cur)} / ${toArabicDigits(z.count)}',
                                style: TextStyle(
                                    color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
