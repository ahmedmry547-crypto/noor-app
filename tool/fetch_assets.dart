// Runs at BUILD time (GitHub Actions / local). Downloads the full Quran text
// (Uthmani + tajweed markup, page + juz numbers) and the Quran font, and
// embeds them in the app as assets, so the installed APK works 100% offline.
import 'dart:convert';
import 'dart:io';

const base = 'https://api.quran.com/api/v4';
final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

Future<dynamic> getJson(String url) async {
  for (var i = 0; i < 6; i++) {
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('Accept', 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 60));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 200) return jsonDecode(body);
      stderr.writeln('HTTP ${res.statusCode} for $url');
    } catch (e) {
      stderr.writeln('retry $i for $url: $e');
    }
    await Future.delayed(Duration(seconds: 2 * (i + 1)));
  }
  throw Exception('Failed to fetch: $url');
}

Future<void> main() async {
  Directory('assets/quran').createSync(recursive: true);

  final chaptersJson = await getJson('$base/chapters?language=ar');
  final chapters = (chaptersJson['chapters'] as List).cast<Map<String, dynamic>>();
  if (chapters.length != 114) throw Exception('Expected 114 chapters');

  final outChapters = <List<dynamic>>[];
  final outVerses = <List<dynamic>>[];

  for (final c in chapters) {
    final id = c['id'] as int;
    final count = c['verses_count'] as int;
    outChapters.add([id, c['name_arabic'], c['revelation_place'] ?? 'makkah', count]);

    final byNumber = <int, List<dynamic>>{};
    var page = 1;
    while (true) {
      final j = await getJson(
          '$base/verses/by_chapter/$id?language=ar&words=false&fields=text_uthmani_tajweed&per_page=50&page=$page');
      for (final v in (j['verses'] as List).cast<Map<String, dynamic>>()) {
        final n = v['verse_number'] as int;
        byNumber[n] = [
          id,
          n,
          (v['page_number'] ?? 0) as int,
          (v['juz_number'] ?? 0) as int,
          (v['text_uthmani_tajweed'] ?? '') as String,
        ];
      }
      final next = j['pagination']?['next_page'];
      if (next == null) break;
      page = next as int;
    }

    // Fallback for the text if the "fields" param was ignored.
    if (byNumber.values.any((e) => (e[4] as String).isEmpty)) {
      final t = await getJson('$base/quran/verses/uthmani_tajweed?chapter_number=$id');
      for (final v in (t['verses'] as List).cast<Map<String, dynamic>>()) {
        final n = int.parse((v['verse_key'] as String).split(':')[1]);
        if (byNumber.containsKey(n)) {
          byNumber[n]![4] = v['text_uthmani_tajweed'] as String;
        }
      }
    }

    if (byNumber.length != count) {
      throw Exception('Chapter $id: got ${byNumber.length} verses, expected $count');
    }
    for (var n = 1; n <= count; n++) {
      final v = byNumber[n]!;
      if ((v[4] as String).isEmpty || (v[2] as int) <= 0) {
        throw Exception('Chapter $id verse $n is missing text/page');
      }
      outVerses.add(v);
    }
    stdout.writeln('chapter $id ok');
    await Future.delayed(const Duration(milliseconds: 150));
  }

  if (outVerses.length != 6236) {
    throw Exception('Expected 6236 verses, got ${outVerses.length}');
  }
  File('assets/quran/quran_data.json')
      .writeAsStringSync(jsonEncode({'c': outChapters, 'v': outVerses}));
  stdout.writeln('Quran data written: ${outVerses.length} verses.');

  await fetchFont();
}

Future<void> fetchFont() async {
  const urls = [
    'https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/AmiriQuran-Regular.ttf',
    'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/amiriquran/AmiriQuran-Regular.ttf',
    'https://github.com/google/fonts/raw/main/ofl/amiriquran/AmiriQuran-Regular.ttf',
  ];
  Directory('assets/fonts').createSync(recursive: true);
  final target = File('assets/fonts/AmiriQuran-Regular.ttf');
  for (final u in urls) {
    try {
      final req = await client.getUrl(Uri.parse(u));
      final res = await req.close().timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) continue;
      final bytes = await res.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      final ok = bytes.length > 50000 &&
          ((bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0) ||
              String.fromCharCodes(bytes.sublist(0, 4)) == 'OTTO' ||
              String.fromCharCodes(bytes.sublist(0, 4)) == 'true');
      if (!ok) continue;
      target.writeAsBytesSync(bytes);
      final pub = File('pubspec.yaml');
      var s = pub.readAsStringSync();
      if (!s.contains('AmiriQuran')) {
        if (!s.endsWith('\n')) s += '\n';
        s += '  fonts:\n'
            '    - family: AmiriQuran\n'
            '      fonts:\n'
            '        - asset: assets/fonts/AmiriQuran-Regular.ttf\n';
        pub.writeAsStringSync(s);
      }
      stdout.writeln('Font embedded.');
      return;
    } catch (e) {
      stderr.writeln('font retry: $e');
    }
  }
  stderr.writeln('WARNING: could not download Quran font; system font will be used.');
}
