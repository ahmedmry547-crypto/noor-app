import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/data/prayer_providers.dart';
import 'quran_api.dart';
import 'quran_providers.dart';
import 'tajweed.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.chapter});
  final Chapter chapter;

  void _legend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('ألوان أحكام التجويد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final (label, color) in tajweedLegend)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  CircleAvatar(radius: 8, backgroundColor: color),
                  const SizedBox(width: 12),
                  Text(label),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final size = ref.watch(quranFontSizeProvider);
    final colored = ref.watch(tajweedOnProvider);
    final verses = ref.watch(versesProvider(chapter.id));

    void setSize(double d) =>
        ref.read(quranFontSizeProvider.notifier).state = (size + d).clamp(20.0, 46.0);

    final base = GoogleFonts.amiriQuran(fontSize: size, height: 2.3, color: cs.onSurface);

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${chapter.name}'),
        actions: [
          IconButton(
            tooltip: 'تلوين التجويد',
            icon: Icon(colored ? Icons.palette : Icons.palette_outlined),
            onPressed: () => ref.read(tajweedOnProvider.notifier).state = !colored,
          ),
          IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => setSize(-2)),
          IconButton(icon: const Icon(Icons.text_increase), onPressed: () => setSize(2)),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _legend(context)),
        ],
      ),
      body: verses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تعذّر تحميل السورة، تأكد من الإنترنت'),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => ref.invalidate(versesProvider(chapter.id)),
                child: const Text('إعادة المحاولة')),
          ]),
        ),
        data: (vs) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (chapter.id != 1 && chapter.id != 9)
              Center(
                child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    style: base.copyWith(color: cs.primary)),
              ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(style: base, children: [
                  for (final v in vs) ...tajweedSpans(v.html, v.number, colored, cs.primary),
                ]),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تمت قراءة السورة'),
              onPressed: () {
                ref.read(quranStatsProvider.notifier).addRead(chapter.versesCount);
                if (!ref.read(trackerProvider).contains('wird')) {
                  ref.read(trackerProvider.notifier).toggle('wird');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل القراءة، تقبّل الله منك')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
