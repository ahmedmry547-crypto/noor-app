import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../home/data/prayer_providers.dart';
import 'bookmarks_screen.dart';
import 'quran_api.dart';
import 'quran_providers.dart';
import 'reading_state.dart';
import 'tajweed.dart';

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key, required this.initialPage, this.highlight});
  final int initialPage;
  final VerseRef? highlight;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late final PageController _pc;
  late int _page;
  VerseRef? _selected;
  Timer? _dwell;
  final Set<int> _counted = {};

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, 604).toInt();
    _selected = widget.highlight;
    _pc = PageController(initialPage: _page - 1);
    _armDwell();
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _armDwell() {
    _dwell?.cancel();
    final p = _page;
    _dwell = Timer(const Duration(seconds: 8), () => _onDwell(p));
  }

  /// The user stayed on this page: count it as read and remember the position.
  void _onDwell(int page) {
    if (!mounted) return;
    final data = ref.read(quranDataProvider).valueOrNull;
    if (data == null) return;
    final vs = data.versesOfPage(page);
    if (vs.isEmpty) return;
    if (_counted.add(page)) {
      ref.read(quranStatsProvider.notifier).addRead(vs.length);
      final today = ref.read(quranStatsProvider)[dayKey(DateTime.now())] ?? 0;
      if (today >= 20 && !ref.read(trackerProvider).contains('wird')) {
        ref.read(trackerProvider.notifier).toggle('wird');
      }
    }
    _savePos(page, vs);
  }

  void _savePos(int page, List<VerseRec> vs) {
    var target = vs.first;
    final s = _selected;
    if (s != null) {
      for (final v in vs) {
        if (v.chapter == s.chapter && v.number == s.verse) target = v;
      }
    }
    ref.read(lastReadProvider.notifier).set(ReadPos(target.chapter, target.number, page));
  }

  void _onTapVerse(VerseRec v) {
    HapticFeedback.selectionClick();
    setState(() => _selected = VerseRef(v.chapter, v.number));
    ref.read(lastReadProvider.notifier).set(ReadPos(v.chapter, v.number, v.page));
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer(builder: (context, ref, _) {
        final colored = ref.watch(tajweedOnProvider);
        final fit = ref.watch(quranFitProvider);
        final size = ref.watch(quranFontSizeProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SwitchListTile(
                title: const Text('تلوين أحكام التجويد'),
                value: colored,
                onChanged: (v) => ref.read(tajweedOnProvider.notifier).state = v,
              ),
              SwitchListTile(
                title: const Text('ملاءمة الصفحة بالكامل'),
                subtitle: const Text('أوقفه لتكبير الخط مع التمرير'),
                value: fit,
                onChanged: (v) => ref.read(quranFitProvider.notifier).state = v,
              ),
              if (!fit)
                Row(children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('حجم الخط')),
                  Expanded(
                    child: Slider(
                      min: 20,
                      max: 44,
                      value: size.clamp(20.0, 44.0).toDouble(),
                      onChanged: (v) => ref.read(quranFontSizeProvider.notifier).state = v,
                    ),
                  ),
                ]),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(quranDataProvider);
    final mc = MushafColors.of(context);
    return Scaffold(
      backgroundColor: mc.outerBg,
      appBar: AppBar(
        backgroundColor: mc.outerBg,
        title: dataAsync.maybeWhen(
          data: (d) {
            final vs = d.versesOfPage(_page);
            return Text(vs.isEmpty ? 'المصحف' : 'سورة ${d.chapter(vs.first.chapter).name}');
          },
          orElse: () => const Text('المصحف'),
        ),
        actions: [
          IconButton(
            tooltip: 'العلامات المرجعية',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          IconButton(
              tooltip: 'إعدادات القراءة', icon: const Icon(Icons.tune), onPressed: _settings),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('بيانات المصحف غير موجودة داخل التطبيق. أعد بناء التطبيق بتشغيل build_apk.sh.'),
          ),
        ),
        data: (d) => Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: d.pageCount,
              onPageChanged: (i) {
                setState(() => _page = i + 1);
                _armDwell();
              },
              itemBuilder: (_, i) => _MushafPage(
                key: ValueKey(i),
                data: d,
                page: i + 1,
                selected: _selected,
                onTapVerse: _onTapVerse,
              ),
            ),
          ),
          if (_selected != null)
            _SelectionBar(
              data: d,
              sel: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
        ]),
      ),
    );
  }
}

class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.data, required this.sel, required this.onClose});
  final QuranData data;
  final VerseRef sel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final v = data.verse(sel.chapter, sel.verse);
    if (v == null) return const SizedBox.shrink();
    final isBm = ref.watch(bookmarksProvider).any((b) => b.chapter == v.chapter && b.verse == v.number);
    return Material(
      color: cs.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(
              child: Text(
                '${data.chapter(v.chapter).name} • الآية ${toArabicDigits(v.number)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'علامة مرجعية',
              icon: Icon(isBm ? Icons.bookmark : Icons.bookmark_border, color: cs.primary),
              onPressed: () =>
                  ref.read(bookmarksProvider.notifier).toggle(v.chapter, v.number, v.page),
            ),
            IconButton(
              tooltip: 'نسخ',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: '${v.plain} \uFD3F${toArabicDigits(v.number)}\uFD3E'
                        ' [${data.chapter(v.chapter).name}]'));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('تم النسخ')));
              },
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          ]),
        ),
      ),
    );
  }
}

class _MushafPage extends ConsumerStatefulWidget {
  const _MushafPage({
    super.key,
    required this.data,
    required this.page,
    required this.selected,
    required this.onTapVerse,
  });
  final QuranData data;
  final int page;
  final VerseRef? selected;
  final void Function(VerseRec) onTapVerse;

  @override
  ConsumerState<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<_MushafPage> {
  final List<TapGestureRecognizer> _recs = [];

  @override
  void dispose() {
    for (final r in _recs) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _rec(VoidCallback f) {
    final r = TapGestureRecognizer()..onTap = f;
    _recs.add(r);
    return r;
  }

  /// Picks a layout width so that the whole page fills the available box
  /// (like a printed Mushaf page) without distorting the text.
  double _designWidth(InlineSpan span, double availW, double availH, double extra) {
    const w0 = 300.0;
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: w0);
    final area = w0 * tp.height;
    tp.dispose();
    final a = availW * area;
    final b = availW * extra;
    final x = (-b + math.sqrt(b * b + 4 * a * availH)) / (2 * a);
    return (1 / x).clamp(availW / 1.12, availW * 1.5).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recs) {
      r.dispose();
    }
    _recs.clear();

    final data = widget.data;
    final verses = data.versesOfPage(widget.page);
    final mc = MushafColors.of(context);
    final colored = ref.watch(tajweedOnProvider);
    final fit = ref.watch(quranFitProvider);
    final fs = ref.watch(quranFontSizeProvider);
    final chapterName = verses.isEmpty ? '' : data.chapter(verses.first.chapter).name;
    final juz = verses.isEmpty ? 0 : verses.first.juz;

    Widget box(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: mc.frameInner, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(t, style: TextStyle(fontSize: 12, color: mc.text, fontWeight: FontWeight.w700)),
        );

    final content = LayoutBuilder(builder: (context, c) {
      final baseSize = fit ? 26.0 : fs;
      final style = TextStyle(fontFamily: 'AmiriQuran', fontSize: baseSize, height: 2.0, color: mc.text);
      final children = <Widget>[];
      final allSpans = <InlineSpan>[];
      var chunk = <InlineSpan>[];
      var banners = 0;
      var bismillahs = 0;

      void flush() {
        if (chunk.isEmpty) return;
        children.add(Text.rich(
          TextSpan(style: style, children: List.of(chunk)),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ));
        chunk = [];
      }

      for (final v in verses) {
        if (v.number == 1) {
          flush();
          banners++;
          children.add(Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mc.frameOuter.withOpacity(.12),
              border: Border.all(color: mc.frameInner, width: 1.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('سورة ${data.chapter(v.chapter).name}',
                style: TextStyle(
                    fontFamily: 'AmiriQuran', fontSize: 22, color: mc.accent, fontWeight: FontWeight.w700)),
          ));
          if (v.chapter != 1 && v.chapter != 9) {
            bismillahs++;
            children.add(Center(child: Text(_bismillah, style: style)));
          }
        }
        final sel = widget.selected != null &&
            widget.selected!.chapter == v.chapter &&
            widget.selected!.verse == v.number;
        final spans = verseSpans(
          v.html,
          v.number,
          colored: colored,
          endColor: mc.accent,
          recognizer: _rec(() => widget.onTapVerse(v)),
          background: sel ? mc.highlight : null,
        );
        chunk.addAll(spans);
        allSpans.addAll(spans);
      }
      flush();

      if (fit) {
        final availW = c.maxWidth - 16;
        final availH = c.maxHeight - 8;
        final extra = banners * 56.0 + bismillahs * baseSize * 2.0;
        final w = _designWidth(TextSpan(style: style, children: allSpans), availW, availH, extra);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: mc.frameOuter,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: mc.page,
            border: Border.all(color: mc.frameInner, width: 1.2),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(children: [
                box('الجزء ${toArabicDigits(juz)}'),
                const Spacer(),
                box('سورة $chapterName'),
              ]),
            ),
            Expanded(child: content),
            if (colored)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final (label, color) in tajweedLegend)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(radius: 4, backgroundColor: color),
                        const SizedBox(width: 3),
                        Text(label, style: TextStyle(fontSize: 9.5, color: mc.text)),
                      ]),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
              child: Row(children: [
                Text('سورة $chapterName', style: TextStyle(fontSize: 12, color: mc.text)),
                const Spacer(),
                Text(toArabicDigits(widget.page),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: mc.text)),
                const Spacer(),
                Text('جزء ${toArabicDigits(juz)}', style: TextStyle(fontSize: 12, color: mc.text)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
