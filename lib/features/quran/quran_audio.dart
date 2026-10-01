import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'quran_audio_api.dart';

class QuranAudioState {
  const QuranAudioState({
    this.currentKey,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  final String? currentKey;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  QuranAudioState copyWith({
    String? currentKey,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => QuranAudioState(
        currentKey: currentKey ?? this.currentKey,
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class QuranAudioController extends StateNotifier<QuranAudioState> {
  QuranAudioController(this._storage) : super(const QuranAudioState()) {
    _playerStateSub = _player.playerStateStream.listen((value) {
      state = state.copyWith(
        isPlaying: value.playing,
        isLoading: value.processingState == ProcessingState.loading ||
            value.processingState == ProcessingState.buffering,
      );
    });
  }

  final QuranAudioStorage _storage;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSub;

  String key(Mp3QuranMoshaf moshaf, int surahId) => '${moshaf.id}:$surahId';

  Future<void> play(Mp3QuranMoshaf moshaf, int surahId, String url) async {
    final k = key(moshaf, surahId);
    try {
      state = state.copyWith(currentKey: k, isLoading: true, clearError: true);
      final local = await _storage.fileFor(moshaf, surahId);
      if (await local.exists() && await local.length() > 0) {
        await _player.setFilePath(local.path);
      } else {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'تعذر تشغيل التلاوة');
    }
  }

  Future<void> toggle(Mp3QuranMoshaf moshaf, int surahId, String url) async {
    final k = key(moshaf, surahId);
    if (state.currentKey == k) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }
    await play(moshaf, surahId, url);
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
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

final quranAudioControllerProvider = StateNotifierProvider<QuranAudioController, QuranAudioState>(
  (ref) => QuranAudioController(ref.read(quranAudioStorageProvider)),
);
