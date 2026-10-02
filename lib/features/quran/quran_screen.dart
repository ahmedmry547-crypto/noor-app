import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'bookmarks_screen.dart';
import 'continue_card.dart';
import 'quran_api.dart';
import 'quran_audio_screen.dart';
import 'reading_state.dart';
import 'search_screen.dart';
import 'stats_screen.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(quranDataProvider);
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(tooltip: 'بحث', icon: const Icon(Icons.search), onPressed: () => go(const SearchScreen())),
          IconButton(
              tooltip: 'العلامات',
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () => go(const BookmarksScreen())),
          IconButton(
              tooltip: 'التلاوات الصوتية',
              icon: const Icon(Icons.headphones_rounded),
              onPressed: () => go(const QuranAudioScreen())),
          IconButton(
              tooltip: 'الإحصائيات',
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () => go(const QuranStatsScreen())),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('بيانات المصحف غير موجودة داخل التطبيق. أعد بناء التطبيق بتشغيل build_apk.sh.'),
          ),
        ),
        data: (d) => DefaultTabController(
          length: 2,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: ContinueReadingCard(),
            ),
            const TabBar(tabs: [Tab(text: 'السور'), Tab(text: 'الأجزاء')]),
            Expanded(
              child: TabBarView(children: [_SurahList(d), _JuzList(d)]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList(this.d);
  final QuranData d;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: d.chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = d.chapters[i];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openMushaf(context, d.firstPageOfChapter(c.id)),
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
              Text('ص ${toArabicDigits(d.firstPageOfChapter(c.id))}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
            ]),
          ),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList(this.d);
  final QuranData d;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 30,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final j = i + 1;
        final v = d.firstVerseOfJuz(j);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: v == null
              ? null
              : () => openMushaf(context, v.page, highlight: VerseRef(v.chapter, v.number)),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(toArabicDigits(j),
                    style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الجزء ${toArabicDigits(j)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (v != null)
                    Text('من سورة ${d.chapter(v.chapter).name} • آية ${toArabicDigits(v.number)}',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
              Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
            ]),
          ),
        );
      },
    );
  }
}
