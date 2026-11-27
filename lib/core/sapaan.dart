/// Sapaan bahasa Inggris sesuai jam perangkat.
String sapaanJam(DateTime now) {
  final h = now.hour;
  if (h >= 4 && h < 11) return 'Selamat Pagi';
  if (h >= 11 && h < 15) return 'Selamat Siang';
  if (h >= 15 && h < 19) return 'Selamat Sore';
  return 'Selamat Malam';
}
