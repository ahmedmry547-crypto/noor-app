import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import 'quran_api.dart';
import 'quran_audio.dart';
import 'quran_providers.dart';

final quranAudioApiProvider = Provider((ref) => QuranAudioApi());
final quranRecitersProvider = FutureProvider<List<AudioReciter>>(
  (ref) => ref.read(quranAudioApiProvider).reciters(),
);

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  final AudioPlayer _player = AudioPlayer();
  AudioReciter? _reciter;
  AudioMoshaf? _moshaf;
  Chapter? _chapter;
  Timer? _sleepTimer;
  int _sleepMinutes = 0;
  String? _loadedUrl;

  @override
  void dispose() {
    _sleepTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  void _selectReciter(AudioReciter value, List<Chapter> chapters) {
    final moshaf = value.moshaf.first;
    final current = _chapter;
    setState(() {
      _reciter = value;
      _moshaf = moshaf;
      if (current == null || !moshaf.surahList.contains(current.id)) {
        _chapter = chapters.firstWhere(
          (c) => moshaf.surahList.contains(c.id),
          orElse: () => chapters.first,
        );
      }
    });
    _loadedUrl = null;
    unawaited(_player.stop());
  }

  void _selectMoshaf(AudioMoshaf value, List<Chapter> chapters) {
    setState(() {
      _moshaf = value;
      if (_chapter == null || !value.surahList.contains(_chapter!.id)) {
        _chapter = chapters.firstWhere(
          (c) => value.surahList.contains(c.id),
          orElse: () => chapters.first,
        );
      }
    });
    _loadedUrl = null;
    unawaited(_player.stop());
  }

  Future<void> _togglePlay() async {
    if (_moshaf == null || _chapter == null) return;
    final url = _moshaf!.urlFor(_chapter!.id);
    if (_loadedUrl != url) {
      await _player.setUrl(url);
      _loadedUrl = url;
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _changeChapter(Chapter value) async {
    if (_moshaf == null) return;
    setState(() => _chapter = value);
    await _player.stop();
    _loadedUrl = null;
    if (mounted) setState(() {});
  }

  Future<void> _seekRelative(int seconds) async {
    final position = _player.position + Duration(seconds: seconds);
    final duration = _player.duration;
    final max = duration ?? const Duration(hours: 24);
    await _player.seek(position < Duration.zero
        ? Duration.zero
        : position > max
            ? max
            : position);
  }

  void _setSleepTimer() {
    final choices = [15, 30, 45, 60, 90];
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('مؤقت النوم', textAlign: TextAlign.right)),
          for (final minutes in choices)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text('$minutes دقيقة'),
              onTap: () {
                Navigator.pop(context);
                _sleepTimer?.cancel();
                _sleepMinutes = minutes;
                _sleepTimer = Timer(Duration(minutes: minutes), () {
                  _player.stop();
                  if (mounted) setState(() => _sleepMinutes = 0);
                });
                setState(() {});
              },
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('إلغاء المؤقت'),
            onTap: () {
              Navigator.pop(context);
              _sleepTimer?.cancel();
              setState(() => _sleepMinutes = 0);
            },
          ),
        ]),
      ),
    );
  }

  String _time(Duration? value) {
    final d = value ?? Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final reciters = ref.watch(quranRecitersProvider);
    final chapters = ref.watch(chaptersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الاستماع')),
      body: reciters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('تعذّر تحميل قائمة القرّاء، تأكد من الإنترنت', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(quranRecitersProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ]),
          ),
        ),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا يوجد قرّاء متاحون الآن'));
          final selected = _reciter ?? list.firstWhere(
            (r) => r.name.contains('مشاري'),
            orElse: () => list.first,
          );
          if (_reciter == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final ch = chapters.value;
                if (ch != null) _selectReciter(selected, ch);
              }
            });
          }

          return chapters.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('تعذّر تحميل أسماء السور')),
            data: (surahs) {
              final reciter = _reciter ?? selected;
              final moshaf = _moshaf ?? reciter.moshaf.first;
              final available = surahs.where((s) => moshaf.surahList.contains(s.id)).toList();
              final chapter = _chapter ?? (available.isNotEmpty ? available.first : surahs.first);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  _selectCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'اختر القارئ',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AudioReciter>(
                        isExpanded: true,
                        value: reciter,
                        items: list.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                        onChanged: (v) => v == null ? null : _selectReciter(v, surahs),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (reciter.moshaf.length > 1) ...[
                    _selectCard(
                      context,
                      icon: Icons.menu_book_outlined,
                      title: 'الرواية',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AudioMoshaf>(
                          isExpanded: true,
                          value: moshaf,
                          items: reciter.moshaf.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                          onChanged: (v) => v == null ? null : _selectMoshaf(v, surahs),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _selectCard(
                    context,
                    icon: Icons.library_music_outlined,
                    title: 'اختر السورة',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Chapter>(
                        isExpanded: true,
                        value: available.contains(chapter) ? chapter : (available.isNotEmpty ? available.first : surahs.first),
                        items: available
                            .map((s) => DropdownMenuItem(value: s, child: Text('سورة ${s.name}')))
                            .toList(),
                        onChanged: (v) => v == null ? null : _changeChapter(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _playerCard(cs, chapter, reciter),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _selectCard(BuildContext context, {required IconData icon, required String title, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            child,
          ]),
        ),
      ]),
    );
  }

  Widget _playerCard(ColorScheme cs, Chapter chapter, AudioReciter reciter) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return AppCard(
          color: cs.primary,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          child: Column(children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: cs.onPrimary, shape: BoxShape.circle),
              child: Icon(Icons.menu_book_rounded, size: 58, color: cs.primary),
            ),
            const SizedBox(height: 18),
            Text('سورة ${chapter.name}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onPrimary)),
            const SizedBox(height: 6),
            Text(reciter.name, style: TextStyle(fontSize: 16, color: cs.onPrimary.withOpacity(.78))),
            const SizedBox(height: 14),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, durSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = durSnap.data ?? Duration.zero;
                    final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
                    return Column(children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(activeTrackColor: cs.onPrimary, inactiveTrackColor: cs.onPrimary.withOpacity(.25), thumbColor: cs.onPrimary),
                        child: Slider(
                          min: 0,
                          max: max,
                          value: value,
                          onChanged: duration == Duration.zero ? null : (v) => _player.seek(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_time(position), style: TextStyle(color: cs.onPrimary.withOpacity(.85))),
                        Text(_time(duration), style: TextStyle(color: cs.onPrimary.withOpacity(.85))),
                      ]),
                    ]);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(
                onPressed: () => _seekRelative(-10),
                icon: Icon(Icons.replay_10, color: cs.onPrimary, size: 34),
                tooltip: '10 ثواني للخلف',
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: cs.onPrimary, shape: BoxShape.circle),
                child: IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: cs.primary, size: 42),
                  tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل',
                ),
              ),
              IconButton(
                onPressed: () => _seekRelative(10),
                icon: Icon(Icons.forward_10, color: cs.onPrimary, size: 34),
                tooltip: '10 ثواني للأمام',
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: cs.onPrimary, side: BorderSide(color: cs.onPrimary.withOpacity(.25))),
                  onPressed: _setSleepTimer,
                  icon: const Icon(Icons.nightlight_round),
                  label: Text(_sleepMinutes == 0 ? 'النوم' : 'النوم $_sleepMinutes د'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('جاهز من آخر موضع', style: TextStyle(color: cs.onPrimary.withOpacity(.65), fontSize: 12)),
          ]),
        );
      },
    );
  }
}
