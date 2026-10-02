import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tajweed.dart';

/// Quran data is embedded in the APK (assets/quran/quran_data.json),
/// so nothing here needs the internet.
class ChapterInfo {
  const ChapterInfo(this.id, this.name, this.place, this.versesCount);
  final int id;
  final String name;
  final String place;
  final int versesCount;
  String get placeAr => place == 'madinah' ? 'مدنية' : 'مكية';
}

class VerseRec {
  VerseRec(this.chapter, this.number, this.page, this.juz, this.html);
  final int chapter;
  final int number;
  final int page;
  final int juz;
  final String html;
  String? _plain;
  String? _norm;
  String get plain => _plain ??= plainText(html);
  String get normalized => _norm ??= normalizeArabic(plain);
}

class QuranData {
  QuranData(this.chapters, this.verses) {
    var maxPage = 0;
    for (var i = 0; i < verses.length; i++) {
      final v = verses[i];
      _chapterFirst.putIfAbsent(v.chapter, () => i);
      if (v.page > maxPage) maxPage = v.page;
    }
    pageCount = maxPage;
    _pageFirst = List.filled(maxPage + 2, -1);
    _pageLast = List.filled(maxPage + 2, -2);
    for (var i = 0; i < verses.length; i++) {
      final p = verses[i].page;
      if (_pageFirst[p] == -1) _pageFirst[p] = i;
      _pageLast[p] = i;
    }
    for (final c in chapters) {
      _byId[c.id] = c;
    }
  }

  factory QuranData.fromJson(Map<String, dynamic> j) {
    final chapters = (j['c'] as List).map((e) {
      final l = e as List;
      return ChapterInfo(l[0] as int, l[1] as String, l[2] as String, l[3] as int);
    }).toList();
    final verses = (j['v'] as List).map((e) {
      final l = e as List;
      return VerseRec(l[0] as int, l[1] as int, l[2] as int, l[3] as int, l[4] as String);
    }).toList();
    return QuranData(chapters, verses);
  }

  final List<ChapterInfo> chapters;
  final List<VerseRec> verses;
  late final int pageCount;
  late final List<int> _pageFirst;
  late final List<int> _pageLast;
  final Map<int, int> _chapterFirst = {};
  final Map<int, ChapterInfo> _byId = {};
  List<VerseRec?>? _juzFirst;

  ChapterInfo chapter(int id) => _byId[id] ?? ChapterInfo(id, 'سورة $id', 'makkah', 0);

  List<VerseRec> versesOfPage(int page) {
    if (page < 1 || page > pageCount || _pageFirst[page] < 0) return const [];
    return verses.sublist(_pageFirst[page], _pageLast[page] + 1);
  }

  VerseRec? verse(int c, int n) {
    final first = _chapterFirst[c];
    if (first == null) return null;
    final i = first + n - 1;
    if (i >= 0 && i < verses.length && verses[i].chapter == c && verses[i].number == n) {
      return verses[i];
    }
    for (final v in verses) {
      if (v.chapter == c && v.number == n) return v;
    }
    return null;
  }

  int firstPageOfChapter(int c) {
    final i = _chapterFirst[c];
    return i == null ? 1 : verses[i].page;
  }

  VerseRec? firstVerseOfJuz(int juz) {
    _juzFirst ??= () {
      final list = List<VerseRec?>.filled(32, null);
      for (final v in verses) {
        if (v.juz >= 1 && v.juz <= 31 && list[v.juz] == null) list[v.juz] = v;
      }
      return list;
    }();
    return _juzFirst![juz];
  }
}

final quranDataProvider = FutureProvider<QuranData>((ref) async {
  final raw = await rootBundle.loadString('assets/quran/quran_data.json');
  return QuranData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
