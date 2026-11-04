String fmtRating(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String albumsWord(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return '$n альбом';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return '$n альбома';
  return '$n альбомов';
}

String fmtDuration(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
