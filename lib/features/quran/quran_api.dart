import 'package:quran_data_dart/quran.dart';

class Chapter {
  Chapter(this.id, this.name, this.versesCount, this.place);
  final int id;
  final String name;
  final int versesCount;
  final String place;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_arabic': name,
        'verses_count': versesCount,
        'revelation_place': place,
      };

  String get placeAr => place == 'Medinan' ? 'مدنية' : 'مكية';
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

/// القرآن النصي يعمل أوفلاين بالكامل.
/// البيانات مضمّنة في quran_data_dart ولا يتم طلب نص السور من الإنترنت.
class QuranApi {
  Future<List<Chapter>> chapters() async {
    final data = await QuranService.getQuranData();
    return data.surahs
        .map((s) => Chapter(
              s.id,
              s.name,
              s.numberOfAyahs,
              s.revelationType,
            ))
        .toList(growable: false);
  }

  Future<List<Verse>> verses(int chapter) async {
    final surah = await QuranService.getSurah(chapter);
    return surah.ayat
        .map((ayah) => Verse(ayah.id, ayah.text))
        .toList(growable: false);
  }

  Future<List<SearchHit>> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return const [];

    final data = await QuranService.getQuranData();
    final hits = <SearchHit>[];
    for (final surah in data.surahs) {
      for (final ayah in surah.ayat) {
        if (ayah.text.contains(query)) {
          hits.add(SearchHit('${surah.id}:${ayah.id}', ayah.text));
          if (hits.length >= 20) return hits;
        }
      }
    }
    return hits;
  }
}
