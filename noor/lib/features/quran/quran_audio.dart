import 'dart:convert';

import 'package:http/http.dart' as http;

class AudioMoshaf {
  AudioMoshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
  });

  final int id;
  final String name;
  final String server;
  final Set<int> surahList;

  factory AudioMoshaf.fromJson(Map<String, dynamic> json) {
    final raw = (json['surah_list'] as String?) ?? '';
    return AudioMoshaf(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'رواية',
      server: (json['server'] as String?) ?? '',
      surahList: raw
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map(int.parse)
          .toSet(),
    );
  }

  String urlFor(int surahId) => '$server${surahId.toString().padLeft(3, '0')}.mp3';
}

class AudioReciter {
  AudioReciter({required this.id, required this.name, required this.moshaf});

  final int id;
  final String name;
  final List<AudioMoshaf> moshaf;

  factory AudioReciter.fromJson(Map<String, dynamic> json) => AudioReciter(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? 'قارئ',
        moshaf: ((json['moshaf'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AudioMoshaf.fromJson)
            .where((m) => m.server.isNotEmpty && m.surahList.isNotEmpty)
            .toList(),
      );
}

class QuranAudioApi {
  static const _url = 'https://mp3quran.net/api/v3/reciters?language=ar';

  Future<List<AudioReciter>> reciters() async {
    final response = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ((json['reciters'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AudioReciter.fromJson)
        .where((r) => r.moshaf.isNotEmpty)
        .toList();
  }
}
