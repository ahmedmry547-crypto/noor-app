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
  ('مد طبيعي (حركتان)', Color(0xFFFF9800)),
  ('مد جائز (2 / 4 / 6)', Color(0xFFFF7043)),
  ('مد واجب (4-5)', Color(0xFFE53935)),
  ('مد لازم (6)', Color(0xFFC62828)),
  ('قلقلة', Color(0xFF29B6F6)),
  ('إخفاء', Color(0xFFEC407A)),
  ('إقلاب', Color(0xFFAB47BC)),
  ('إدغام', Color(0xFF66BB6A)),
  ('غنّة', Color(0xFFFFCA28)),
  ('حرف لا يُنطق / همزة وصل', Color(0xFF9E9E9E)),
];

final _endRe = RegExp(r'<span[^>]*class=["\x27]?end["\x27]?[^>]*>.*?</span>', dotAll: true);
final _tagRe = RegExp(
    r'<tajweed\s+class=["\x27]?([a-zA-Z_]+)["\x27]?[^>]*>(.*?)</tajweed>',
    dotAll: true);
final _anyTag = RegExp(r'<[^>]+>');

List<InlineSpan> tajweedSpans(String html, int number, bool colored, Color endColor) {
  final clean = html.replaceAll(_endRe, '');
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _tagRe.allMatches(clean)) {
    if (m.start > last) {
      spans.add(TextSpan(text: clean.substring(last, m.start).replaceAll(_anyTag, '')));
    }
    spans.add(TextSpan(
      text: m.group(2)!.replaceAll(_anyTag, ''),
      style: colored ? TextStyle(color: _colors[m.group(1)]) : null,
    ));
    last = m.end;
  }
  if (last < clean.length) {
    spans.add(TextSpan(text: clean.substring(last).replaceAll(_anyTag, '')));
  }
  spans.add(TextSpan(
    text: ' \uFD3F${toArabicDigits(number)}\uFD3E ',
    style: TextStyle(color: endColor),
  ));
  return spans;
}
