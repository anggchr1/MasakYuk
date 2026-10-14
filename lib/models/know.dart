/// Ensiklopedia bahan + tempat makan (seed lokal, backend belakangan).
class IngredientInfo {
  final String id;
  final String nama;
  final String asal;
  final String kat;
  final String desc;
  final String fakta;
  final String wiki;
  const IngredientInfo({
    required this.id,
    required this.nama,
    required this.asal,
    required this.kat,
    required this.desc,
    required this.fakta,
    required this.wiki,
  });
  factory IngredientInfo.fromJson(Map<String, dynamic> j) =>
      IngredientInfo(
        id: j['id'] as String? ?? '',
        nama: j['nama'] as String? ?? '',
        asal: j['asal'] as String? ?? '',
        kat: j['kat'] as String? ?? 'Lainnya',
        desc: j['desc'] as String? ?? '',
        fakta: j['fakta'] as String? ?? '',
        wiki: j['wiki'] as String? ?? '',
      );
}

class PlaceInfo {
  final String id;
  final String nama;
  final String jenis;
  final String alamat;
  final double lat;
  final double lng;
  final String harga;
  final String hargaNote;
  final double rating;
  final int ulasan;
  final String desc;
  final bool contoh; // true = seed contoh, ganti data live belakangan
  const PlaceInfo({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.alamat,
    required this.lat,
    required this.lng,
    required this.harga,
    required this.hargaNote,
    required this.rating,
    required this.ulasan,
    required this.desc,
    required this.contoh,
  });
  factory PlaceInfo.fromJson(Map<String, dynamic> j) => PlaceInfo(
        id: j['id'] as String? ?? '',
        nama: j['nama'] as String? ?? '',
        jenis: j['jenis'] as String? ?? '',
        alamat: j['alamat'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        harga: j['harga'] as String? ?? '',
        hargaNote: j['harga_note'] as String? ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ulasan: (j['ulasan'] as num?)?.toInt() ?? 0,
        desc: j['desc'] as String? ?? '',
        contoh: j['contoh'] as bool? ?? false,
      );
}
