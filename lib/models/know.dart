/// Ensiklopedia bahan + tempat makan (seed lokal, backend belakangan).
class IngredientInfo {
  final String id;
  final String nama;
  final String asal;
  final String kat;
  final String desc;
  final String fakta;
  final String wiki;
  final String latin;
  final String karakter;
  final String simpan;
  final List<String> pairs;
  const IngredientInfo({
    required this.id,
    required this.nama,
    required this.asal,
    required this.kat,
    required this.desc,
    required this.fakta,
    required this.wiki,
    this.latin = '',
    this.karakter = '',
    this.simpan = '',
    this.pairs = const [],
  });
  factory IngredientInfo.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).toList();
    return IngredientInfo(
      id: j['id'] as String? ?? '',
      nama: j['nama'] as String? ?? '',
      asal: j['asal'] as String? ?? '',
      kat: j['kat'] as String? ?? 'Lainnya',
      desc: j['desc'] as String? ?? '',
      fakta: j['fakta'] as String? ?? '',
      wiki: j['wiki'] as String? ?? '',
      latin: j['latin'] as String? ?? '',
      karakter: j['karakter'] as String? ?? '',
      simpan: j['simpan'] as String? ?? '',
      pairs: strList(j['pairs']),
    );
  }
}

/// Pasangan default per kategori (dipakai bila artikel tak menyebut).
List<String> defaultPairs(String kat) {
  switch (kat) {
    case 'Rempah Utama':
      return ['Bawang Merah', 'Bawang Putih', 'Ketumbar', 'Kemiri'];
    case 'Bumbu Daun':
      return ['Serai', 'Daun Salam', 'Lengkuas', 'Santan Kelapa'];
    case 'Cabai':
      return ['Bawang Merah', 'Tomat', 'Terasi', 'Gula Merah'];
    case 'Bawang':
      return ['Cabai', 'Tomat', 'Kemiri', 'Terasi'];
    case 'Penyegar':
      return ['Gula Merah', 'Cabai', 'Garam', 'Es Batu'];
    default:
      return ['Bawang Merah', 'Bawang Putih', 'Garam', 'Minyak'];
  }
}

class PlaceProduct {
  final String nama;
  final String desc;
  final String harga;
  const PlaceProduct(
      {required this.nama,
      required this.desc,
      required this.harga});
  factory PlaceProduct.fromJson(Map<String, dynamic> j) =>
      PlaceProduct(
        nama: j['nama'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        harga: j['harga'] as String? ?? '',
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
  final String jam;
  final List<PlaceProduct> unggulan;
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
    this.jam = '',
    this.unggulan = const [],
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
        jam: j['jam'] as String? ?? '',
        unggulan: ((j['unggulan'] as List?) ?? [])
            .map((e) => PlaceProduct.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
