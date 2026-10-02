import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_api.dart';
import 'reader_screen.dart';
import 'reading_state.dart';

void openMushaf(BuildContext context, int page, {VerseRef? highlight}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MushafScreen(initialPage: page, highlight: highlight)),
  );
}

class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(lastReadProvider);
    final data = ref.watch(quranDataProvider).valueOrNull;
    if (pos == null || data == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final name = data.chapter(pos.chapter).name;
    return AppCard(
      color: cs.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bookmark_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text('متابعة القراءة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text('آخر موضع قرأت منه:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          Text('سورة $name  •  الآية ${toArabicDigits(pos.verse)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FilledButton.icon(
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('متابعة القراءة'),
            onPressed: () =>
                openMushaf(context, pos.page, highlight: VerseRef(pos.chapter, pos.verse)),
          ),
        ],
      ),
    );
  }
}
