import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import 'audio_downloads.dart';
import 'mp3quran_service.dart';
import 'quran_api.dart';

class QuranAudioScreen extends StatefulWidget {
  const QuranAudioScreen({super.key, required this.chapters});
  final List<Chapter> chapters;

  @override
  State<QuranAudioScreen> createState() => _QuranAudioScreenState();
}

class _QuranAudioScreenState extends State<QuranAudioScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Mp3QuranService _service = Mp3QuranService();
  final AudioDownloadManager _downloads = AudioDownloadManager();
  final TextEditingController _search = TextEditingController();

  List<Mp3QuranReciter> _reciters = [];
  Mp3QuranReciter? _reciter;
  Mp3QuranMushaf? _mushaf;
  int _surah = 1;
  bool _loadingCatalog = true;
  String? _catalogError;
  Set<String> _downloaded = <String>{};
  final Map<String, double> _progress = {};
  bool _downloadingAll = false;

  String _key(int mushafId, int surah) => '$mushafId-$surah';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _search.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final list = await _service.reciters();
      if (!mounted) return;
      setState(() {
        _reciters = list;
        _reciter = list.isNotEmpty ? list.first : null;
        _mushaf = (_reciter != null && _reciter!.moshaf.isNotEmpty) ? _reciter!.moshaf.first : null;
        _loadingCatalog = false;
      });
      await _refreshDownloads();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _catalogError = 'تعذر تحميل قائمة القراء. تأكد من الإنترنت وحاول مرة أخرى.';
      });
    }
  }

  Future<void> _refreshDownloads() async {
    final keys = await _downloads.downloadedKeys();
    if (mounted) setState(() => _downloaded = keys);
  }

  List<Chapter> get _availableChapters {
    final allowed = _mushaf?.surahList ?? <int>{};
    return widget.chapters.where((c) => allowed.isEmpty || allowed.contains(c.id)).toList();
  }

  Future<void> _play(int surah) async {
    final mushaf = _mushaf;
    if (mushaf == null) return;
    final local = await _downloads.localPath(mushaf.id, surah);
    try {
      if (local != null) {
        await _player.setFilePath(local);
      } else {
        await _player.setUrl(mushaf.urlForSurah(surah));
      }
      if (mounted) setState(() => _surah = surah);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل السورة. تأكد من الإنترنت أو أعد المحاولة.')),
      );
    }
  }

  Future<void> _download(int surah) async {
    final mushaf = _mushaf;
    if (mushaf == null) return;
    final key = _key(mushaf.id, surah);
    if (_downloaded.contains(key)) return;

    setState(() => _progress[key] = 0);
    try {
      await _downloads.download(
        mushafId: mushaf.id,
        surah: surah,
        url: mushaf.urlForSurah(surah),
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() => _progress[key] = total > 0 ? received / total : 0);
        },
      );
      if (!mounted) return;
      setState(() {
        _progress.remove(key);
        _downloaded = {..._downloaded, key};
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحميل السورة ويمكن تشغيلها بدون إنترنت.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _progress.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحميل السورة. حاول مرة أخرى.')));
    }
  }

  Future<void> _delete(int surah) async {
    final mushaf = _mushaf;
    if (mushaf == null) return;
    await _downloads.delete(mushafId: mushaf.id, surah: surah);
    await _refreshDownloads();
    if (mounted) setState(() {});
  }

  Future<void> _downloadAll() async {
    final mushaf = _mushaf;
    if (mushaf == null || _downloadingAll) return;
    final chapters = _availableChapters;
    if (chapters.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحميل المصحف كاملًا'),
        content: Text('سيتم تحميل ${toArabicDigits(chapters.length)} سورة على الجهاز. قد يحتاج ذلك إلى مساحة كبيرة ووقت طويل حسب حجم المصحف وسرعة الإنترنت.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ابدأ التحميل')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _downloadingAll = true);
    try {
      for (final c in chapters) {
        if (!mounted) break;
        if (_downloaded.contains(_key(mushaf.id, c.id))) continue;
        await _downloads.download(
          mushafId: mushaf.id,
          surah: c.id,
          url: mushaf.urlForSurah(c.id),
          onProgress: (received, total) {
            if (!mounted) return;
            final key = _key(mushaf.id, c.id);
            setState(() => _progress[key] = total > 0 ? received / total : 0);
          },
        );
        if (mounted) {
          setState(() {
            final key = _key(mushaf.id, c.id);
            _progress.remove(key);
            _downloaded = {..._downloaded, key};
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتمل تحميل المصحف المتاح لهذا القارئ.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('توقف التحميل بسبب خطأ في الاتصال. يمكنك استكمال السور المتبقية لاحقًا.')));
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  Future<void> _chooseReciter() async {
    final result = await showModalBottomSheet<Mp3QuranReciter>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _reciters.where((r) => r.name.contains(query)).toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .86,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن القارئ...'),
                        onChanged: (v) => setSheetState(() => query = v.trim()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Align(alignment: Alignment.centerRight, child: Text('عدد القراء: ${toArabicDigits(filtered.length)}')),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final r = filtered[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(r.letter.isEmpty ? 'ق' : r.letter)),
                            title: Text(r.name),
                            subtitle: Text('${toArabicDigits(r.moshaf.length)} مصحف/رواية'),
                            selected: r.id == _reciter?.id,
                            onTap: () => Navigator.pop(context, r),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    await _player.stop();
    setState(() {
      _reciter = result;
      _mushaf = result.moshaf.first;
      _surah = 1;
      _progress.clear();
    });
    await _refreshDownloads();
  }

  Future<void> _chooseMushaf() async {
    final reciter = _reciter;
    if (reciter == null) return;
    final result = await showModalBottomSheet<Mp3QuranMushaf>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: reciter.moshaf.length,
          itemBuilder: (_, i) {
            final m = reciter.moshaf[i];
            return ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(m.name),
              subtitle: Text('${toArabicDigits(m.surahTotal)} سورة'),
              selected: m.id == _mushaf?.id,
              onTap: () => Navigator.pop(context, m),
            );
          },
        ),
      ),
    );
    if (result == null) return;
    await _player.stop();
    setState(() {
      _mushaf = result;
      _surah = _availableChapters.isEmpty ? 1 : _availableChapters.first.id;
      _progress.clear();
    });
    await _refreshDownloads();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCatalog) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_catalogError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('استماع القرآن')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 60),
          const SizedBox(height: 12),
          Text(_catalogError!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () { setState(() { _loadingCatalog = true; _catalogError = null; }); _loadCatalog(); }, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ]))),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final reciter = _reciter!;
    final mushaf = _mushaf!;
    final chapters = _availableChapters;
    final matching = chapters.where((c) => c.id == _surah).toList();
    final currentChapter = matching.isNotEmpty ? matching.first : (chapters.isNotEmpty ? chapters.first : widget.chapters.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن - صوت وتنزيل'),
        actions: [
          IconButton(tooltip: 'اختيار القارئ', onPressed: _chooseReciter, icon: const Icon(Icons.people_alt_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: cs.primary,
            child: Column(children: [
              const CircleAvatar(radius: 38, backgroundColor: Colors.white, child: Icon(Icons.headphones_rounded, size: 44, color: Color(0xFF1F7A5C))),
              const SizedBox(height: 12),
              Text(reciter.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(mushaf.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(onPressed: _chooseReciter, icon: const Icon(Icons.person_search), label: const Text('تغيير القارئ')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: reciter.moshaf.length > 1 ? _chooseMushaf : null, icon: const Icon(Icons.library_books), label: const Text('اختيار الرواية / المصحف')),
            ]),
          ),
          const SizedBox(height: 12),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return AppCard(child: Column(children: [
                Text('سورة ${currentChapter.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (_, p) {
                    final position = p.data ?? Duration.zero;
                    final total = _player.duration ?? Duration.zero;
                    final max = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
                    final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
                    return Column(children: [
                      Slider(value: value, max: max, onChanged: total == Duration.zero ? null : (v) => _player.seek(Duration(milliseconds: v.toInt()))),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fmt(position)), Text(_fmt(total))]),
                    ]);
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(iconSize: 32, onPressed: () => _player.seek(Duration(seconds: (_player.position.inSeconds - 10).clamp(0, 999999))), icon: const Icon(Icons.replay_10)),
                  IconButton(iconSize: 66, onPressed: playing ? _player.pause : () => _play(_surah), icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill)),
                  IconButton(iconSize: 32, onPressed: () => _player.seek(_player.position + const Duration(seconds: 10)), icon: const Icon(Icons.forward_10)),
                ]),
              ]));
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('السور المتاحة: ${toArabicDigits(chapters.length)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            FilledButton.icon(onPressed: _downloadingAll ? null : _downloadAll, icon: const Icon(Icons.download_for_offline), label: Text(_downloadingAll ? 'جاري التحميل' : 'تحميل الكل')),
          ]),
          const SizedBox(height: 8),
          ...chapters.map((c) => _surahTile(c, cs)),
          const SizedBox(height: 8),
          const Text('المصدر الصوتي: MP3Quran.net. التحميل يحفظ الصوت داخل التطبيق لتشغيله لاحقًا بدون إنترنت.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _surahTile(Chapter c, ColorScheme cs) {
    final mushaf = _mushaf!;
    final key = _key(mushaf.id, c.id);
    final downloaded = _downloaded.contains(key);
    final progress = _progress[key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: cs.primaryContainer, child: Text(toArabicDigits(c.id), style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('سورة ${c.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${toArabicDigits(c.versesCount)} آية', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ])),
          IconButton(tooltip: 'تشغيل', onPressed: () => _play(c.id), icon: const Icon(Icons.play_circle_fill)),
          if (progress != null)
            SizedBox(width: 34, height: 34, child: CircularProgressIndicator(value: progress == 0 ? null : progress, strokeWidth: 3))
          else if (downloaded)
            PopupMenuButton<String>(
              tooltip: 'تم التحميل',
              onSelected: (v) { if (v == 'delete') _delete(c.id); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('حذف التنزيل'))],
              child: const Icon(Icons.download_done_rounded),
            )
          else
            IconButton(tooltip: 'تحميل أوفلاين', onPressed: () => _download(c.id), icon: const Icon(Icons.download_for_offline_outlined)),
        ]),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
