import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'continue_card.dart';
import 'quran_api.dart';
import 'reading_state.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(bookmarksProvider);
    final data = ref.watch(quranDataProvider).valueOrNull;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('العلامات المرجعية')),
      body: list.isEmpty
          ? const Center(child: Text('لا توجد علامات بعد. اضغط على أي آية ثم أيقونة العلامة.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final b = list[i];
                final name = data?.chapter(b.chapter).name ?? '${b.chapter}';
                final text = data?.verse(b.chapter, b.verse)?.plain ?? '';
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openMushaf(context, b.page, highlight: VerseRef(b.chapter, b.verse)),
                  child: AppCard(
                    child: Row(children: [
                      Icon(Icons.bookmark, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('سورة $name • الآية ${toArabicDigits(b.verse)}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (text.isNotEmpty)
                            Text(text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(bookmarksProvider.notifier).remove(b),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
