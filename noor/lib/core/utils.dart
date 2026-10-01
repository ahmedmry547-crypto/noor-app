String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

String toArabicDigits(int n) {
  const d = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}
