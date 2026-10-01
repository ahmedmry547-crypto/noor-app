import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../home/data/prayer_providers.dart';
import 'qiyam_provider.dart';

class QiyamScreen extends ConsumerWidget {
  const QiyamScreen({super.key});

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, DateTime start) async {
    final rk = TextEditingController();
    final rd = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('سجل القيام'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: rk,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الركعات'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: rd,
            decoration: const InputDecoration(labelText: 'ما قرأته (سورة / آيات)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      final mins = DateTime.now().difference(start).inMinutes;
      await ref.read(qiyamLogProvider.notifier).add(
            QiyamEntry(DateTime.now(), mins, int.tryParse(rk.text) ?? 0, rd.text.trim()),
          );
    }
    ref.read(qiyamStartProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dayAsync = ref.watch(prayerDayProvider);
    final now = ref.watch(tickerProvider).value ?? DateTime.now();
    final start = ref.watch(qiyamStartProvider);
    final log = ref.watch(qiyamLogProvider);
    final month = log.where((e) => e.date.year == now.year && e.date.month == now.month).length;
    final tf = DateFormat('h:mm a', 'ar');

    return Scaffold(
      appBar: AppBar(title: const Text('قيام الليل')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        dayAsync.when(
          loading: () => const AppCard(child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const AppCard(child: Text('تعذّر حساب الليل')),
          data: (day) {
            final q = computeQiyam(day, now);
            final inside = now.isAfter(q.lastThirdStart) && now.isBefore(q.nightEnd);
            return AppCard(
              color: cs.primary,
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الثلث الأخير من الليل',
                    style: TextStyle(color: cs.onPrimary.withOpacity(.8))),
                const SizedBox(height: 4),
                Text(tf.format(q.lastThirdStart),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: cs.onPrimary)),
                const SizedBox(height: 8),
                Text(
                  inside
                      ? 'أنت الآن في الثلث الأخير، وقت التنزّل الإلهي'
                      : 'يبدأ بعد ${_fmt(q.lastThirdStart.difference(now))}',
                  style: TextStyle(color: cs.onPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'منتصف الليل ${tf.format(q.midnight)}  •  الفجر ${tf.format(q.nightEnd)}',
                  style: TextStyle(fontSize: 12, color: cs.onPrimary.withOpacity(.8)),
                ),
              ]),
            );
          },
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(children: [
            if (start != null) ...[
              Text(_fmt(now.difference(start)),
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('إنهاء وتسجيل'),
                onPressed: () => _finish(context, ref, start),
              ),
            ] else ...[
              const Text('ابدأ جلسة قيام لتسجيل وقتها وما قرأت فيها'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('بدء جلسة القيام'),
                onPressed: () => ref.read(qiyamStartProvider.notifier).state = DateTime.now(),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(children: [
            const Icon(Icons.nightlight_round),
            const SizedBox(width: 12),
            Text('ليالي القيام هذا الشهر: ${toArabicDigits(month)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('السجل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (log.isEmpty)
          Text('لا توجد جلسات بعد', style: TextStyle(color: cs.onSurfaceVariant)),
        for (final e in log.take(30))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('EEEE d MMMM', 'ar').format(e.date),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${toArabicDigits(e.minutes)} دقيقة  •  ${toArabicDigits(e.rakaat)} ركعة'
                  '${e.read.isEmpty ? '' : '\nالقراءة: ${e.read}'}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
