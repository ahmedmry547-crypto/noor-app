import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Chapter {
  Chapter(this.id, this.name, this.versesCount, this.place);
  final int id;
  final String name;
  final int versesCount;
  final String place;

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        j['id'] as int,
        j['name_arabic'] as String,
        j['verses_count'] as int,
        (j['revelation_place'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_arabic': name,
        'verses_count': versesCount,
        'revelation_place': place,
      };

  String get placeAr => place == 'madinah' ? 'مدنية' : 'مكية';
}

class Verse {
  Verse(this.number, this.html);
  final int number;
  final String html;
}

class SearchHit {
  SearchHit(this.key, this.text);
  final String key;
  final String text;
  int get chapter => int.parse(key.split(':')[0]);
  int get verse => int.parse(key.split(':')[1]);
}

/// Quran.com public API. Each surah is downloaded once, then cached locally.
class QuranApi {
  static const _base = 'https://api.quran.com/api/v4';

  Future<dynamic> _getJson(String url) async {
    final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<List<Chapter>> chapters() async {
    final p = await SharedPreferences.getInstance();
    final cached = p.getString('chapters_v1');
    if (cached != null) {
      return (jsonDecode(cached) as List)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final j = await _getJson('$_base/chapters?language=ar');
    final list = (j['chapters'] as List)
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
        .toList();
    await p.setString('chapters_v1', jsonEncode(list.map((c) => c.toJson()).toList()));
    return list;
  }

  Future<List<Verse>> verses(int chapter) async {
    final p = await SharedPreferences.getInstance();
    final key = 'surah_tajweed_$chapter';
    final cached = p.getString(key);
    if (cached != null) {
      return (jsonDecode(cached) as List)
          .map((e) => Verse(e['n'] as int, e['h'] as String))
          .toList();
    }
    final j = await _getJson('$_base/quran/verses/uthmani_tajweed?chapter_number=$chapter');
    final list = (j['verses'] as List).map((e) {
      final k = (e['verse_key'] as String).split(':')[1];
      return Verse(int.parse(k), e['text_uthmani_tajweed'] as String);
    }).toList();
    await p.setString(key, jsonEncode(list.map((v) => {'n': v.number, 'h': v.html}).toList()));
    return list;
  }

  Future<List<SearchHit>> search(String q) async {
    final j = await _getJson(
        '$_base/search?q=${Uri.encodeQueryComponent(q)}&size=20&language=ar');
    final res = (j['search']?['results'] as List?) ?? [];
    return res
        .map((e) => SearchHit(
              e['verse_key'] as String,
              ((e['text'] as String?) ?? '').replaceAll(RegExp(r'<[^>]+>'), ''),
            ))
        .toList();
  }
}
