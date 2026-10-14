/// Estimasi harga resep dari tabel harga bahan (transparan, tanpa AI).
/// Aturan: jumlahkan harga bahan yang cocok; label jujur bila tak lengkap.
/// HARGA = estimasi belanja wajar per masak (Jember, Okt 2026), BUKAN harga pasar resmi.
class Money {
  /// "Rp22.500" / "Rp18rb" ala desain.
  static String rp(int v) {
    if (v >= 1000 && v % 1000 == 0) return 'Rp${v ~/ 1000}rb';
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  static String range(int min, int max) => '±${rp((min + max) ~/ 2)}';
}
