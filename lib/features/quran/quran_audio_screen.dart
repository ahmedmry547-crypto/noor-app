import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'quran_audio.dart';
import 'quran_audio_api.dart';

String _sizeText(int bytes) {
  if (bytes <= 0) return 'غير معروف';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  return '${value.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

class QuranAudioScreen extends ConsumerStatefulWidget {
  const QuranAudioScreen({super.key});

  @override
  ConsumerState<QuranAudioScreen> createState() => _QuranAudioScreenState();
}

class _QuranAudioScreenState extends ConsumerState<QuranAudioScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(quranRecitersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('التلاوات الصوتية'),
        actions: [
          IconButton(
            tooltip: 'التنزيلات',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranDownloadsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'تحديث القراء',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(quranRecitersProvider);
            },
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('تعذر تحميل قائمة القراء. تأكد من الإنترنت ثم حاول مرة أخرى.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(quranRecitersProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (reciters) {
          final filtered = reciters.where((r) {
            final q = _query.trim().toLowerCase();
            return q.isEmpty || r.name.toLowerCase().contains(q);
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  controller: _search,
                  textDirection: TextDirection.rtl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم القارئ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${toArabicDigits(filtered.length)} قارئ متاح',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final reciter = filtered[i];
                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            reciter.letter.isEmpty ? 'ق' : reciter.letter.characters.first,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(reciter.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${toArabicDigits(reciter.moshaf.length)} مصحف/رواية'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReciterMoshafScreen(reciter: reciter)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReciterMoshafScreen extends StatelessWidget {
  const ReciterMoshafScreen({super.key, required this.reciter});
  final Mp3QuranReciter reciter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(reciter.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(reciter.letter.isEmpty ? 'ق' : reciter.letter.characters.first),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reciter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('اختر الرواية أو المصحف المتاح لهذا القارئ.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final moshaf in reciter.moshaf)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.library_music_rounded),
                  title: Text(moshaf.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${toArabicDigits(moshaf.surahTotal)} سورة متاحة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MoshafSurahsScreen(reciter: reciter, moshaf: moshaf)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Full in-app playback controls. Android notification controls are supplied
/// by just_audio_background using the same AudioPlayer instance.
class QuranAudioPlayerCard extends ConsumerWidget {
  const QuranAudioPlayerCard({super.key});

  String _time(Duration value) {
    final totalSeconds = value.inSeconds.clamp(0, 359999);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final hours = minutes ~/ 60;
    final mm = (minutes % 60).toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioControllerProvider);
    final controller = ref.read(quranAudioControllerProvider.notifier);
    if (audio.currentKey == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.headphones_rounded, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.currentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        audio.currentArtist.isEmpty ? 'القرآن الكريم' : audio.currentArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            StreamBuilder<Duration?>(
              stream: controller.durationStream,
              builder: (context, durationSnap) {
                final duration = durationSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: controller.positionStream,
                  initialData: Duration.zero,
                  builder: (context, positionSnap) {
                    final position = positionSnap.data ?? Duration.zero;
                    final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                    final value = position.inMilliseconds.clamp(0, duration.inMilliseconds > 0 ? duration.inMilliseconds : 1).toDouble();
                    return Column(
                      children: [
                        Slider(
                          min: 0,
                          max: max,
                          value: value,
                          onChanged: duration.inMilliseconds <= 0
                              ? null
                              : (v) => controller.seek(Duration(milliseconds: v.round())),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_time(position), style: Theme.of(context).textTheme.labelSmall),
                            Text(_time(duration), style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'السورة السابقة',
                  iconSize: 30,
                  onPressed: controller.hasPrevious ? controller.previousSurah : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton(
                  tooltip: 'رجوع 10 ثوانٍ',
                  iconSize: 27,
                  onPressed: controller.back10,
                  icon: const Icon(Icons.replay_10_rounded),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: audio.isLoading
                      ? null
                      : () => audio.isPlaying ? controller.pause() : controller.resume(),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(13),
                    minimumSize: const Size(54, 54),
                  ),
                  child: audio.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'تقديم 10 ثوانٍ',
                  iconSize: 27,
                  onPressed: controller.forward10,
                  icon: const Icon(Icons.forward_10_rounded),
                ),
                IconButton(
                  tooltip: 'السورة التالية',
                  iconSize: 30,
                  onPressed: controller.hasNext ? controller.nextSurah : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MoshafSurahsScreen extends ConsumerStatefulWidget {
  const MoshafSurahsScreen({super.key, required this.reciter, required this.moshaf});
  final Mp3QuranReciter reciter;
  final Mp3QuranMoshaf moshaf;

  @override
  ConsumerState<MoshafSurahsScreen> createState() => _MoshafSurahsScreenState();
}

class _MoshafSurahsScreenState extends ConsumerState<MoshafSurahsScreen> {
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloading = {};
  int? _estimatedBytes;
  int _knownSizeFiles = 0;
  bool _calculatingSize = false;
  bool _downloadAll = false;
  int _downloadedAll = 0;

  Future<void> _download(int surahId, String name) async {
    final key = '${widget.moshaf.id}:$surahId';
    if (_downloading[key] == true) return;
    setState(() {
      _downloading[key] = true;
      _progress[key] = 0;
    });
    try {
      final api = ref.read(quranAudioApiProvider);
      final storage = ref.read(quranAudioStorageProvider);
      await storage.download(
        api.audioUrl(widget.moshaf, surahId),
        widget.moshaf,
        surahId,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() => _progress[key] = total > 0 ? received / total : 0);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloading[key] = false;
        _progress[key] = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تنزيل سورة $name للأوفلاين')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading[key] = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تنزيل السورة')));
    }
  }

  Future<void> _play(int surahId) async {
    final api = ref.read(quranAudioApiProvider);
    final surahName = ref.read(quranAudioSurahsProvider).valueOrNull
            ?.firstWhere((s) => s.id == surahId, orElse: () => const Mp3QuranSurah(id: 0, name: '', makkia: true))
            .name ??
        '';
    final namesList = ref.read(quranAudioSurahsProvider).valueOrNull ?? const <Mp3QuranSurah>[];
    await ref.read(quranAudioControllerProvider.notifier).toggle(
          widget.moshaf,
          surahId,
          api.audioUrl(widget.moshaf, surahId),
          reciterName: widget.reciter.name,
          surahNames: {for (final x in namesList) x.id: x.name},
        );
    if (!mounted) return;
    final error = ref.read(quranAudioControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (surahName.isNotEmpty) {
      // Keep the interaction quiet; the mini player state is visible on the row.
    }
  }

  Future<void> _calculateSize() async {
    if (_calculatingSize) return;
    setState(() => _calculatingSize = true);
    final api = ref.read(quranAudioApiProvider);
    final storage = ref.read(quranAudioStorageProvider);
    var total = 0;
    var knownFiles = 0;
    final ids = widget.moshaf.surahList;
    for (var start = 0; start < ids.length; start += 6) {
      final batch = ids.skip(start).take(6).toList();
      final sizes = await Future.wait(batch.map((id) async {
        if (await storage.exists(widget.moshaf, id)) {
          return storage.size(widget.moshaf, id);
        }
        return await storage.remoteSize(api.audioUrl(widget.moshaf, id));
      }));
      for (final size in sizes) {
        if (size != null && size > 0) {
          total += size;
          knownFiles++;
        }
      }
      if (mounted) setState(() {
        _estimatedBytes = total;
        _knownSizeFiles = knownFiles;
      });
    }
    if (mounted) setState(() => _calculatingSize = false);
  }

  Future<void> _downloadAllSurahs(List<Mp3QuranSurah> all) async {
    if (_downloadAll) return;
    final ids = widget.moshaf.surahList;
    final available = ids.map((id) => all.firstWhere(
          (s) => s.id == id,
          orElse: () => Mp3QuranSurah(id: id, name: 'سورة $id', makkia: true),
        )).toList();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحميل المصحف كاملًا'),
        content: Text(
          'سيتم تنزيل ${toArabicDigits(available.length)} سورة إلى مساحة التطبيق لتعمل بدون إنترنت.\n\n${_estimatedBytes != null && _knownSizeFiles == available.length ? 'الحجم التقريبي: ${_sizeText(_estimatedBytes!)}\n\n' : ''}قد يحتاج ذلك إلى مساحة كبيرة ووقت حسب سرعة الإنترنت.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('بدء التحميل')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _downloadAll = true;
      _downloadedAll = 0;
    });
    final api = ref.read(quranAudioApiProvider);
    final storage = ref.read(quranAudioStorageProvider);
    for (final surah in available) {
      try {
        await storage.download(
          api.audioUrl(widget.moshaf, surah.id),
          widget.moshaf,
          surah.id,
          onProgress: (received, total) {
            if (!mounted) return;
            final key = '${widget.moshaf.id}:${surah.id}';
            setState(() => _progress[key] = total > 0 ? received / total : 0);
          },
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنزيل ${surah.name}')));
      }
      if (mounted) setState(() => _downloadedAll++);
    }
    if (mounted) {
      setState(() => _downloadAll = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتمل تحميل المصحف المتاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(quranAudioSurahsProvider);
    final audio = ref.watch(quranAudioControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moshaf.name),
        actions: [
          IconButton(
            tooltip: 'التنزيلات',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranDownloadsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const QuranAudioPlayerCard(),
          Expanded(
            child: surahsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذر تحميل أسماء السور')),
        data: (allSurahs) {
          final ids = widget.moshaf.surahList;
          final surahs = ids
              .map((id) => allSurahs.firstWhere(
                    (s) => s.id == id,
                    orElse: () => Mp3QuranSurah(id: id, name: 'سورة $id', makkia: true),
                  ))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _estimatedBytes == null
                                  ? 'يمكنك تنزيل أي سورة أو المصحف كاملًا للعمل بدون إنترنت.'
                                  : (_knownSizeFiles == surahs.length
                                      ? 'الحجم التقريبي للمصحف: ${_sizeText(_estimatedBytes!)}'
                                      : 'تم حساب ${toArabicDigits(_knownSizeFiles)} من ${toArabicDigits(surahs.length)} ملفًا: ${_sizeText(_estimatedBytes!)}'),
                            ),
                          ),
                          if (_calculatingSize)
                            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _calculatingSize ? null : _calculateSize,
                            icon: const Icon(Icons.calculate_outlined),
                            label: const Text('حساب الحجم'),
                          ),
                          FilledButton.icon(
                            onPressed: _downloadAll ? null : () => _downloadAllSurahs(allSurahs),
                            icon: _downloadAll
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.download_for_offline),
                            label: Text(_downloadAll
                                ? '$_downloadedAll / ${surahs.length}'
                                : 'تحميل المصحف كاملًا'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: surahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = surahs[i];
                    final key = '${widget.moshaf.id}:${s.id}';
                    final downloading = _downloadAll || _downloading[key] == true;
                    final progress = _progress[key] ?? 0;
                    final current = audio.currentKey == key;
                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            child: Text(toArabicDigits(s.id), style: const TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('سورة ${s.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(s.makkia ? 'مكية' : 'مدنية', style: Theme.of(context).textTheme.bodySmall),
                                if (downloading && progress > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: LinearProgressIndicator(value: progress.clamp(0, 1)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: current && audio.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                            icon: Icon(current && audio.isPlaying ? Icons.pause_circle : Icons.play_circle_fill),
                            onPressed: () => _play(s.id),
                          ),
                          FutureBuilder<bool>(
                            future: ref.read(quranAudioStorageProvider).exists(widget.moshaf, s.id),
                            builder: (_, snapshot) {
                              final exists = snapshot.data == true || progress >= 1;
                              return IconButton(
                                tooltip: exists ? 'محمل أوفلاين' : 'تحميل',
                                icon: Icon(exists ? Icons.download_done : Icons.download_for_offline_outlined),
                                onPressed: exists || downloading ? null : () => _download(s.id, s.name),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuranDownloadsScreen extends ConsumerStatefulWidget {
  const QuranDownloadsScreen({super.key});

  @override
  ConsumerState<QuranDownloadsScreen> createState() => _QuranDownloadsScreenState();
}

class _QuranDownloadsScreenState extends ConsumerState<QuranDownloadsScreen> {
  List<dynamic>? _files;
  int _bytes = 0;

  Future<void> _load() async {
    final storage = ref.read(quranAudioStorageProvider);
    final files = await storage.downloadedFiles();
    final bytes = await storage.downloadedBytes();
    if (mounted) setState(() {
      _files = files;
      _bytes = bytes;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف كل التنزيلات؟'),
        content: const Text('سيتم حذف الملفات الصوتية المحفوظة على الجهاز فقط.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    final storage = ref.read(quranAudioStorageProvider);
    for (final file in await storage.downloadedFiles()) {
      await file.delete();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التنزيلات والأوفلاين'),
        actions: [
          if (files != null && files.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearAll),
        ],
      ),
      body: files == null
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? const Center(child: Text('لا توجد سور محملة حتى الآن.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.storage_rounded),
                            const SizedBox(width: 10),
                            Text('${toArabicDigits(files.length)} ملف • ${_sizeText(_bytes)}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final file in files)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              children: [
                                const Icon(Icons.music_note_rounded),
                                const SizedBox(width: 10),
                                Expanded(child: Text(file.path.split('/').last)),
                                Text(_sizeText(file.lengthSync()), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
