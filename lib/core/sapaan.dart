/// Sapaan bahasa Inggris sesuai jam perangkat.
String sapaanJam(DateTime now) {
  final h = now.hour;
  if (h >= 4 && h < 11) return 'Good Morning';
  if (h >= 11 && h < 15) return 'Good Afternoon';
  if (h >= 15 && h < 19) return 'Good Evening';
  return 'Good Night';
}
