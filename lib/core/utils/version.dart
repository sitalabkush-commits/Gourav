/// True if [current] is older than [minimum] (both like "1.2.3").
bool isOlderVersion(String current, String minimum) {
  List<int> parse(String v) =>
      v.split('+').first.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  final a = parse(current), b = parse(minimum);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}
