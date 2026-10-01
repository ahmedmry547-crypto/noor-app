import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Mp3QuranMushaf {
  const Mp3QuranMushaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.surahList,
    required this.type,
  });

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final Set<int> surahList;
  final int type;

  factory Mp3QuranMushaf.fromJson(Map<String, dynamic> j) {
    final raw = (j['surah_list'] ?? '').toString();
    final ids = raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
    return Mp3QuranMushaf(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] ?? '').toString(),
      server: (j['server'] ?? '').toString().replaceAll(RegExp(r'(?<!:)/+$'), '/'),
      surahTotal: (j['surah_total'] as num?)?.toInt() ?? ids.length,
      surahList: ids,
      type: (j['moshaf_type'] as num?)?.toInt() ?? 0,
    );
  }

  String urlForSurah(int surah) => '${server}${surah.toString().padLeft(3, '0')}.mp3';
}

class Mp3QuranReciter {
  const Mp3QuranReciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  final int id;
  final String name;
  final String letter;
  final List<Mp3QuranMushaf> moshaf;

  factory Mp3QuranReciter.fromJson(Map<String, dynamic> j) {
    final list = (j['moshaf'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Mp3QuranMushaf.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.server.isNotEmpty)
        .toList();
    return Mp3QuranReciter(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] ?? '').toString(),
      letter: (j['letter'] ?? '').toString(),
      moshaf: list,
    );
  }
}

class Mp3QuranService {
  static const _url = 'https://www.mp3quran.net/api/v3/reciters?language=ar';
  static const _cacheKey = 'mp3quran_reciters_ar_v1';

  Future<List<Mp3QuranReciter>> reciters() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        return _decode(cached);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    final response = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final body = utf8.decode(response.bodyBytes);
    final result = _decode(body);
    await prefs.setString(_cacheKey, body);
    return result;
  }

  List<Mp3QuranReciter> _decode(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return (json['reciters'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Mp3QuranReciter.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.moshaf.isNotEmpty)
        .toList();
  }
}
