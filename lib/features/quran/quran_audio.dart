import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'quran_audio_api.dart';

class QuranAudioState {
  const QuranAudioState({
    this.currentKey,
    this.currentTitle = '',
    this.currentArtist = '',
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  final String? currentKey;
  final String currentTitle;
  final String currentArtist;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  QuranAudioState copyWith({
    String? currentKey,
    String? currentTitle,
    String? currentArtist,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      QuranAudioState(
        currentKey: currentKey ?? this.currentKey,
        currentTitle: currentTitle ?? this.currentTitle,
        currentArtist: currentArtist ?? this.currentArtist,
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Background audio: playing a surah queues the reciter's whole mushaf, so
/// Next / Previous work from the Android media notification and lock screen.
class QuranAudioController extends StateNotifier<QuranAudioState> {
  QuranAudioController(this._storage) : super(const QuranAudioState()) {
    _playerStateSub = _player.playerStateStream.listen((value) {
      state = state.copyWith(
        isPlaying: value.playing,
        isLoading: value.processingState == ProcessingState.loading ||
            value.processingState == ProcessingState.buffering,
      );
    });
    _indexSub = _player.currentIndexStream.listen((index) {
      final seq = _player.sequence;
      if (index == null || index < 0 || index >= seq.length) return;
      final tag = seq[index].tag;
      if (tag is MediaItem) {
        state = state.copyWith(
          currentKey: tag.id,
          currentTitle: tag.title,
          currentArtist: tag.artist ?? '',
        );
      }
    });
  }

  final QuranAudioStorage _storage;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<int?> _indexSub;
  Uri? _art;

  /// Streams used by the in-app player UI. The same AudioPlayer instance is
  /// also connected to just_audio_background, so the notification and the UI
  /// always control the same playback position.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  String key(Mp3QuranMoshaf moshaf, int surahId) => '${moshaf.id}:$surahId';

  String _url(Mp3QuranMoshaf m, int id) {
    final base = m.server.endsWith('/') ? m.server : '${m.server}/';
    return '$base${id.toString().padLeft(3, '0')}.mp3';
  }

  /// App artwork shown in the media notification (copied once from assets).
  Future<Uri?> _artUri() async {
    if (_art != null) return _art;
    try {
      final dir = await getTemporaryDirectory();
      final f = File(p.join(dir.path, 'ayat_quran_art.png'));
      if (!f.existsSync()) {
        final bytes = await rootBundle.load('assets/images/app_icon.png');
        await f.writeAsBytes(bytes.buffer.asUint8List());
      }
      return _art = Uri.file(f.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> play(
    Mp3QuranMoshaf moshaf,
    int surahId,
    String url, {
    String reciterName = '',
    Map<int, String> surahNames = const {},
  }) async {
    final k = key(moshaf, surahId);
    try {
      state = state.copyWith(currentKey: k, isLoading: true, clearError: true);
      try {
        await Permission.notification.request(); // Android 13+
      } catch (_) {}
      final art = await _artUri();
      final ids = moshaf.surahList.contains(surahId)
          ? moshaf.surahList
          : <int>[surahId];

      final children = <AudioSource>[];
      for (final id in ids) {
        final local = await _storage.fileFor(moshaf, id);
        final has = local.existsSync() && local.lengthSync() > 0;
        final name = surahNames[id] ?? 'سورة $id';
        final tag = MediaItem(
          id: key(moshaf, id),
          album: moshaf.name,
          title: name.startsWith('سورة') ? name : 'سورة $name',
          artist: reciterName.isEmpty ? 'القرآن الكريم' : reciterName,
          artUri: art,
        );
        children.add(AudioSource.uri(
          has ? Uri.file(local.path) : Uri.parse(id == surahId ? url : _url(moshaf, id)),
          tag: tag,
        ));
      }
      final initial = ids.indexOf(surahId);
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: children),
        initialIndex: initial < 0 ? 0 : initial,
      );
      unawaitedPlay();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذر تشغيل التلاوة');
    }
  }

  void unawaitedPlay() {
    _player.play();
  }

  Future<void> toggle(
    Mp3QuranMoshaf moshaf,
    int surahId,
    String url, {
    String reciterName = '',
    Map<int, String> surahNames = const {},
  }) async {
    final k = key(moshaf, surahId);
    if (state.currentKey == k && _player.audioSource != null) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }
    await play(moshaf, surahId, url, reciterName: reciterName, surahNames: surahNames);
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) async {
    final duration = _player.duration;
    if (duration == null) return;
    final target = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    await _player.seek(target);
  }

  Future<void> seekBy(Duration delta) async {
    await seek(_player.position + delta);
  }

  Future<void> back10() => seekBy(const Duration(seconds: -10));

  Future<void> forward10() => seekBy(const Duration(seconds: 10));

  Future<void> previousSurah() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      if (!_player.playing) await _player.play();
    }
  }

  Future<void> nextSurah() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      if (!_player.playing) await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _indexSub.cancel();
    _player.dispose();
    super.dispose();
  }
}

final quranAudioApiProvider = Provider((ref) => QuranAudioCatalogApi());
final quranAudioStorageProvider = Provider((ref) => QuranAudioStorage());

final quranRecitersProvider = FutureProvider<List<Mp3QuranReciter>>(
  (ref) => ref.read(quranAudioApiProvider).reciters(),
);

final quranAudioSurahsProvider = FutureProvider<List<Mp3QuranSurah>>(
  (ref) => ref.read(quranAudioApiProvider).surahs(),
);

final quranAudioControllerProvider =
    StateNotifierProvider<QuranAudioController, QuranAudioState>(
  (ref) => QuranAudioController(ref.read(quranAudioStorageProvider)),
);
