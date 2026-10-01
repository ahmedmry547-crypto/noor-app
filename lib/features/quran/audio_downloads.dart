import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioDownloadManager {
  static const _metaKey = 'noor_mp3quran_downloads_v1';

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/quran_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _key(int mushafId, int surah) => '$mushafId-$surah';

  Future<Set<String>> downloadedKeys() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_metaKey)?.toSet() ?? <String>{};
  }

  Future<String?> localPath(int mushafId, int surah) async {
    final key = _key(mushafId, surah);
    final keys = await downloadedKeys();
    if (!keys.contains(key)) return null;
    final dir = await _dir();
    final file = File('${dir.path}/$key.mp3');
    if (await file.exists() && await file.length() > 0) return file.path;
    await _removeKey(key);
    return null;
  }

  Future<void> _addKey(String key) async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList(_metaKey)?.toSet() ?? <String>{};
    keys.add(key);
    await p.setStringList(_metaKey, keys.toList());
  }

  Future<void> _removeKey(String key) async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getStringList(_metaKey)?.toSet() ?? <String>{};
    keys.remove(key);
    await p.setStringList(_metaKey, keys.toList());
  }

  Future<void> download({
    required int mushafId,
    required int surah,
    required String url,
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await _dir();
    final key = _key(mushafId, surah);
    final part = File('${dir.path}/$key.part');
    final target = File('${dir.path}/$key.mp3');

    if (await target.exists() && await target.length() > 0) {
      await _addKey(key);
      onProgress?.call(await target.length(), await target.length());
      return;
    }

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, response.contentLength ?? -1);
      }
      await sink.close();
      if (!await part.exists() || await part.length() == 0) {
        throw Exception('empty download');
      }
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      await _addKey(key);
      onProgress?.call(received, response.contentLength ?? received);
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> delete({required int mushafId, required int surah}) async {
    final dir = await _dir();
    final key = _key(mushafId, surah);
    final file = File('${dir.path}/$key.mp3');
    if (await file.exists()) await file.delete();
    await _removeKey(key);
  }

  Future<int> storageBytes() async {
    final dir = await _dir();
    var total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.mp3')) {
        total += await entity.length();
      }
    }
    return total;
  }
}
