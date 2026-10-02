import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/utils.dart';

const _colors = <String, Color>{
  'ham_wasl': Color(0xFF9E9E9E),
  'slnt': Color(0xFF9E9E9E),
  'laam_shamsiyah': Color(0xFF9E9E9E),
  'madda_normal': Color(0xFFFF9800),
  'madda_permissible': Color(0xFFFF7043),
  'madda_obligatory': Color(0xFFE53935),
  'madda_necessary': Color(0xFFC62828),
  'qalqalah': Color(0xFF29B6F6),
  'ikhfa': Color(0xFFEC407A),
  'ikhfa_shafawi': Color(0xFFEC407A),
  'iqlab': Color(0xFFAB47BC),
  'idgham_ghunnah': Color(0xFF66BB6A),
  'idgham_wo_ghunnah': Color(0xFF66BB6A),
  'idgham_shafawi': Color(0xFF66BB6A),
  'idgham_mutajanisayn': Color(0xFF66BB6A),
  'idgham_mutaqaribayn': Color(0xFF66BB6A),
  'ghunnah': Color(0xFFFFCA28),
};

const tajweedLegend = <(String, Color)>[
  ('مد طبيعي', Color(0xFFFF9800)),
  ('مد جائز', Color(0xFFFF7043)),
  ('مد واجب', Color(0xFFE53935)),
  ('مد لازم', Color(0xFFC62828)),
  ('قلقلة', Color(0xFF29B6F6)),
  ('إخفاء', Color(0xFFEC407A)),
  ('إقلاب', Color(0xFFAB47BC)),
  ('إدغام', Color(0xFF66BB6A)),
  ('غنّة', Color(0xFFFFCA28)),
  ('لا يُنطق', Color(0xFF9E9E9E)),
];

final _endRe = RegExp(r'<span[^>]*class=["\x27]?end["\x27]?[^>]*>.*?</span>', dotAll: true);
final _tagRe = RegExp(
    r'<tajweed\s+class=["\x27]?([a-zA-Z_]+)["\x27]?[^>]*>(.*?)</tajweed>',
    dotAll: true);
final _anyTag = RegExp(r'<[^>]+>');

/// Verse text with diacritics, markup removed.
String plainText(String html) =>
    html.replaceAll(_endRe, '').replaceAll(_anyTag, '').trim();

final _diacritics = RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

/// For searching: strips tashkeel/Quranic marks and unifies letter forms.
String normalizeArabic(String s) => s
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[\u0671\u0622\u0623\u0625]'), '\u0627')
    .replaceAll('\u0649', '\u064A')
    .replaceAll('\u0629', '\u0647')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Builds the spans of one verse (tajweed-colored) ending with the ﴿n﴾ marker.
List<InlineSpan> verseSpans(
  String html,
  int number, {
  required bool colored,
  required Color endColor,
  GestureRecognizer? recognizer,
  Color? background,
}) {
  TextStyle? style(Color? c) =>
      (c == null && background == null) ? null : TextStyle(color: c, backgroundColor: background);

  final clean = html.replaceAll(_endRe, '');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _tagRe.allMatches(clean)) {
    if (m.start > last) {
      spans.add(TextSpan(
        text: clean.substring(last, m.start).replaceAll(_anyTag, ''),
        style: style(null),
        recognizer: recognizer,
      ));
    }
    spans.add(TextSpan(
      text: m.group(2)!.replaceAll(_anyTag, ''),
      style: style(colored ? _colors[m.group(1)] : null),
      recognizer: recognizer,
    ));
    last = m.end;
  }
  if (last < clean.length) {
    spans.add(TextSpan(
      text: clean.substring(last).replaceAll(_anyTag, ''),
      style: style(null),
      recognizer: recognizer,
    ));
  }
  spans.add(TextSpan(
    text: ' \uFD3F${toArabicDigits(number)}\uFD3E ',
    style: style(endColor),
    recognizer: recognizer,
  ));
  return spans;
}
