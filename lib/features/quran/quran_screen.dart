import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_providers.dart';
import 'reader_screen.dart';
import 'search_screen.dart';
import 'stats_screen.dart';
import 'audio_screen.dart';

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
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            tooltip: 'استماع القرآن',
            icon: const Icon(Icons.headphones_rounded),
            onPressed: () => chapters.whenData((list) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuranAudioScreen(chapters: list)),
              );
            }),
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
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuranAudioScreen(chapters: list)),
              ),
              child: AppCard(
                color: cs.primary,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.headphones_rounded, size: 34, color: Color(0xFF1F7A5C)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('استماع القرآن', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('اختر القارئ والسورة واستمع بصوت القارئ', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final c in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
