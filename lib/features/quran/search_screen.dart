import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'continue_card.dart';
import 'quran_api.dart';
import 'reading_state.dart';
import 'tajweed.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  List<VerseRec> _results = const [];
  String _q = '';

  void _run(String q) {
    final data = ref.read(quranDataProvider).valueOrNull;
    final nq = normalizeArabic(q);
    if (data == null || nq.length < 2) {
      setState(() {
        _q = q;
        _results = const [];
      });
      return;
    }
    final found = <VerseRec>[];
    for (final v in data.verses) {
      if (v.normalized.contains(nq)) {
        found.add(v);
        if (found.length >= 100) break;
      }
    }
    setState(() {
      _q = q;
      _results = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(quranDataProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'ابحث في القرآن (بدون إنترنت)...', border: InputBorder.none),
          onChanged: _run,
        ),
      ),
      body: _q.trim().length < 2
          ? const Center(child: Text('اكتب كلمة أو جزءًا من آية'))
          : _results.isEmpty
              ? const Center(child: Text('لا نتائج'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final v = _results[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          openMushaf(context, v.page, highlight: VerseRef(v.chapter, v.number)),
                      child: AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.plain,
                              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.9)),
                          const SizedBox(height: 6),
                          Text(
                            'سورة ${data?.chapter(v.chapter).name ?? v.chapter} • الآية ${toArabicDigits(v.number)} • ص ${toArabicDigits(v.page)}',
                            style: TextStyle(color: cs.primary, fontSize: 12),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
