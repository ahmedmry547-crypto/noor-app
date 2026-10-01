import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_api.dart';
import 'quran_providers.dart';
import 'reader_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Future<List<SearchHit>>? _future;

  void _run(String q) {
    if (q.trim().isEmpty) return;
    setState(() => _future = ref.read(quranApiProvider).search(q.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'ابحث في القرآن...', border: InputBorder.none),
          onSubmitted: _run,
        ),
      ),
      body: _future == null
          ? const Center(child: Text('اكتب كلمة أو جزء من آية'))
          : FutureBuilder<List<SearchHit>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء البحث في المصحف'));
                }
                final hits = snap.data!;
                if (hits.isEmpty) return const Center(child: Text('لا نتائج'));
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: hits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final h = hits[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final list = ref.read(chaptersProvider).value;
                        if (list == null) return;
                        final c = list.firstWhere((c) => c.id == h.chapter);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ReaderScreen(chapter: c)));
                      },
                      child: AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h.text, style: const TextStyle(fontSize: 18, height: 1.9)),
                          const SizedBox(height: 6),
                          Text('${toArabicDigits(h.chapter)} : ${toArabicDigits(h.verse)}',
                              style: TextStyle(color: cs.primary, fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
