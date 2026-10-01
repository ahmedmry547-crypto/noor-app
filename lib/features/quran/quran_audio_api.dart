import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mp3QuranSurah {
  const Mp3QuranSurah({
    required this.id,
    required this.name,
    required this.makkia,
    this.startPage = 0,
    this.endPage = 0,
  });

  final int id;
  final String name;
  final bool makkia;
  final int startPage;
  final int endPage;

  factory Mp3QuranSurah.fromJson(Map<String, dynamic> json) => Mp3QuranSurah(
        id: json['id'] as int,
        name: (json['name'] as String).trim(),
        makkia: (json['makkia'] as int? ?? 1) == 1,
        startPage: json['start_page'] as int? ?? 0,
        endPage: json['end_page'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'makkia': makkia ? 1 : 0,
        'start_page': startPage,
        'end_page': endPage,
      };
}

class Mp3QuranMoshaf {
  const Mp3QuranMoshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final List<int> surahList;

  factory Mp3QuranMoshaf.fromJson(Map<String, dynamic> json) => Mp3QuranMoshaf(
        id: json['id'] as int,
        name: (json['name'] as String).trim(),
        server: (json['server'] as String).trim(),
        surahTotal: json['surah_total'] as int? ?? 0,
        moshafType: json['moshaf_type'] as int? ?? 0,
        surahList: ((json['surah_list'] as String?) ?? '')
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'server': server,
        'surah_total': surahTotal,
        'moshaf_type': moshafType,
        'surah_list': surahList.join(','),
      };
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
  final List<Mp3QuranMoshaf> moshaf;

  factory Mp3QuranReciter.fromJson(Map<String, dynamic> json) => Mp3QuranReciter(
        id: json['id'] as int,
        name: (json['name'] as String).trim(),
        letter: (json['letter'] as String? ?? '').trim(),
        moshaf: ((json['moshaf'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Mp3QuranMoshaf.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'letter': letter,
        'moshaf': moshaf.map((m) => m.toJson()).toList(),
      };
}

class QuranAudioCatalogApi {
  static const _base = 'https://www.mp3quran.net/api/v3';
  static const _recitersKey = 'mp3quran_reciters_ar_v1';
  static const _surahsKey = 'mp3quran_suwar_ar_v1';

  Future<dynamic> _getJson(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<Mp3QuranReciter>> reciters({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = prefs.getString(_recitersKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) => Mp3QuranReciter.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    }

    final json = await _getJson('$_base/reciters?language=ar');
    final list = ((json['reciters'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Mp3QuranReciter.fromJson)
        .where((r) => r.moshaf.isNotEmpty)
        .toList();
    await prefs.setString(_recitersKey, jsonEncode(list.map((r) => r.toJson()).toList()));
    return list;
  }

  Future<List<Mp3QuranSurah>> surahs({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cached = prefs.getString(_surahsKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) => Mp3QuranSurah.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.length == 114) return list;
      }
    }

    final json = await _getJson('$_base/suwar?language=ar');
    final list = ((json['suwar'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Mp3QuranSurah.fromJson)
        .toList();
    await prefs.setString(_surahsKey, jsonEncode(list.map((s) => s.toJson()).toList()));
    return list;
  }

  String audioUrl(Mp3QuranMoshaf moshaf, int surahId) {
    final base = moshaf.server.endsWith('/') ? moshaf.server : '${moshaf.server}/';
    return '$base${surahId.toString().padLeft(3, '0')}.mp3';
  }
}

class QuranAudioStorage {
  static const _folder = 'quran_audio';

  Future<Directory> _directory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, _folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> fileFor(Mp3QuranMoshaf moshaf, int surahId) async {
    final dir = await _directory();
    return File(p.join(dir.path, '${moshaf.id}_${surahId.toString().padLeft(3, '0')}.mp3'));
  }

  Future<bool> exists(Mp3QuranMoshaf moshaf, int surahId) async {
    return (await fileFor(moshaf, surahId)).exists();
  }

  Future<int> size(Mp3QuranMoshaf moshaf, int surahId) async {
    final file = await fileFor(moshaf, surahId);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  Future<void> delete(Mp3QuranMoshaf moshaf, int surahId) async {
    final file = await fileFor(moshaf, surahId);
    if (await file.exists()) await file.delete();
  }

  Future<List<File>> downloadedFiles() async {
    final dir = await _directory();
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.mp3'))
        .toList();
  }

  Future<int> downloadedBytes() async {
    var total = 0;
    for (final file in await downloadedFiles()) {
      total += await file.length();
    }
    return total;
  }

  Future<File> download(
    String url,
    Mp3QuranMoshaf moshaf,
    int surahId, {
    void Function(int received, int total)? onProgress,
  }) async {
    final target = await fileFor(moshaf, surahId);
    if (await target.exists() && await target.length() > 0) {
      onProgress?.call(await target.length(), await target.length());
      return target;
    }

    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();

    final request = http.Request('GET', Uri.parse(url));
    request.headers['Accept'] = 'audio/mpeg';
    final response = await request.send().timeout(const Duration(minutes: 10));
    if (response.statusCode != 200) {
      throw Exception('تعذر تنزيل الصوت (${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = partial.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await partial.rename(target.path);
    onProgress?.call(received, total == 0 ? received : total);
    return target;
  }

  Future<int?> remoteSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return int.tryParse(response.headers['content-length'] ?? '');
      }
    } catch (_) {}
    return null;
  }
}
