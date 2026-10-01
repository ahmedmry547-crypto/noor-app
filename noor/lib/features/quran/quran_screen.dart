import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_providers.dart';
import 'reader_screen.dart';
import 'listen_screen.dart';
import 'search_screen.dart';
import 'stats_screen.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final chapters = ref.watch(chaptersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            tooltip: 'الاستماع للقرآن',
            icon: const Icon(Icons.headphones_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ListenScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const QuranStatsScreen())),
          ),
        ],
      ),
      body: chapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('يلزم اتصال بالإنترنت لأول تحميل'),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => ref.invalidate(chaptersProvider),
                child: const Text('إعادة المحاولة')),
          ]),
        ),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = list[i];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ReaderScreen(chapter: c))),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(toArabicDigits(c.id),
                        style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('سورة ${c.name}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${c.placeAr} • ${toArabicDigits(c.versesCount)} آية',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ]),
                  ),
                  Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
