import 'dart:async';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/know.dart';

/// Tempat makan, pasar & toko di sekitar koordinat.
/// Dua sumber OSM: Nominatim (cepat, tempat makan + pasar) dan Overpass
/// (lebih lengkap, tapi server publiknya sering 429/502).
class PlacesService {
  static const _ua = 'MasakYuk/1.0 (+https://app.masakyuk.jagoankode.my.id)';

  /// Kategori tampilan: Tempat Makan (resto/warung), Kafe, dan Pasar.
  static const _kategori = {
    'amenity=marketplace': 'Pasar',
    'amenity=restaurant': 'Tempat Makan',
    'amenity=fast_food': 'Tempat Makan',
    'amenity=cafe': 'Kafe',
  };

  /// Toko belanja (sayur, daging, kelontong, supermarket) masuk "Pasar".
  static const _toko = {
    'greengrocer': 'Pasar',
    'butcher': 'Pasar',
    'seafood': 'Pasar',
    'convenience': 'Pasar',
    'supermarket': 'Pasar',
    'bakery': 'Pasar',
    'deli': 'Pasar',
    'general': 'Pasar',
    'beverages': 'Pasar',
  };

  /// Server publik Overpass sering membalas 429/502; coba mirror berikutnya.
  static const _mirror = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  /// OSM kadang salah tag: rumah sakit ber-tag `restaurant`, atau pasar
  /// yang bukan pasar bahan (sepeda, burung, bunga). Nama jadi saringan akhir.
  static const _bukanMakan = [
    'rumah sakit', 'rs ', 'rs.', 'rsu', 'klinik', 'puskesmas', 'apotek',
    'hotel', 'penginapan', 'sekolah', 'kampus', 'kantor', 'spbu',
    'terminal', 'stasiun', 'masjid', 'gereja', 'bank',
  ];
  static const _bukanPasar = [
    'sepeda', 'burung', 'bunga', 'ikan hias', 'loak', 'hewan', 'antik',
    'buku', 'mainan', 'pancing',
  ];

  static bool _namaTidakCocok(String nama, String jenis) {
    final n = ' ${nama.toLowerCase()} ';
    final daftar = jenis == 'Pasar' ? _bukanPasar : _bukanMakan;
    return daftar.any(n.contains);
  }

  /// Alamat lengkap dari kolom Nominatim (jalan, nomor, kelurahan, kota).
  static String _alamat(Map a) {
    final jalan = [a['road'], a['house_number']]
        .where((s) => s != null && '$s'.trim().isNotEmpty)
        .join(' ');
    return [
      jalan,
      a['suburb'] ?? a['village'] ?? a['neighbourhood'],
      a['city'] ?? a['town'] ?? a['municipality'],
      a['postcode'],
    ].where((s) => s != null && '$s'.trim().isNotEmpty).join(', ');
  }

  /// Info tambahan OSM yang membuat detail tempat tidak kosong.
  static List<String> _fasilitas(Map t) => [
        if ('${t['cuisine'] ?? ''}'.trim().isNotEmpty)
          'Masakan ${'${t['cuisine']}'.replaceAll(';', ', ')}',
        if (t['takeaway'] == 'yes' || t['takeaway'] == 'only')
          'Bisa dibawa pulang',
        if (t['outdoor_seating'] == 'yes') 'Area outdoor',
        if (t['internet_access'] == 'wlan' || t['internet_access'] == 'yes')
          'Wi-Fi',
        if (t['wheelchair'] == 'yes') 'Akses kursi roda',
      ];

  /// `image` OSM hanya dipakai bila benar-benar URL.
  static String _foto(Map t) {
    final f = '${t['image'] ?? ''}'.trim();
    return f.startsWith('http') ? f : '';
  }

  /// Tempat makan & pasar dari Nominatim (4 request, ±5 km).
  static Future<List<PlaceInfo>> sekitar(double lat, double lng) async {
    const d = 0.045; // ±5 km
    final viewbox =
        '${lng - d},${lat + d},${lng + d},${lat - d}';
    final out = <PlaceInfo>[];
    var ok = 0;
    for (final e in _kategori.entries) {
      try {
        final uri = Uri.parse(
            'https://nominatim.openstreetmap.org/search'
            '?format=jsonv2&addressdetails=1&extratags=1'
            '&limit=40&bounded=1&viewbox=$viewbox&${e.key}');
        final res = await http
            .get(uri, headers: const {'User-Agent': _ua})
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          ok++;
          out.addAll(dariNominatim(json.decode(res.body), e.value));
        }
      } catch (_) {
        // kategori ini dilewati
      }
      // Batas resmi Nominatim: 1 request/detik.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    }
    if (ok == 0) throw 'Peta sedang sibuk. Coba lagi sebentar.';
    return rapikan(out, lat, lng);
  }

  /// Belanja (pasar, toko bahan, kelontong) dari Overpass.
  /// Melempar error bila semua mirror gagal — pemanggil boleh mengabaikan.
  static Future<List<PlaceInfo>> toko(double lat, double lng) async {
    final shop = _toko.keys.join('|');
    final q = '''
[out:json][timeout:20];
(
  node["amenity"="marketplace"](around:5000,$lat,$lng);
  way["amenity"="marketplace"](around:5000,$lat,$lng);
  node["shop"~"^($shop)\$"](around:5000,$lat,$lng);
  way["shop"~"^($shop)\$"](around:5000,$lat,$lng);
);
out center 100;''';

    Object? gagal;
    for (final url in _mirror) {
      try {
        final res = await http
            .post(
              Uri.parse(url),
              // Overpass menolak request tanpa UA yang jelas (406).
              headers: const {
                'User-Agent': _ua,
                'Accept': 'application/json',
              },
              body: {'data': q},
            )
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          gagal = 'HTTP ${res.statusCode}';
          continue; // 429/502/504: mirror berikutnya
        }
        return dariJson(json.decode(res.body), lat, lng);
      } on TimeoutException {
        gagal = 'timeout';
      } catch (e) {
        gagal = e;
      }
    }
    throw 'Peta sedang sibuk ($gagal).';
  }

  /// Petakan hasil Nominatim (JSON array) jadi `PlaceInfo`.
  static List<PlaceInfo> dariNominatim(dynamic body, String jenis) {
    final out = <PlaceInfo>[];
    for (final raw in (body as List)) {
      final e = (raw as Map).cast<String, dynamic>();
      final nama = '${e['name'] ?? ''}'.trim();
      if (nama.isEmpty) continue;
      if (_namaTidakCocok(nama, jenis)) continue;
      final lat = double.tryParse('${e['lat']}');
      final lng = double.tryParse('${e['lon']}');
      if (lat == null || lng == null) continue;
      final a = ((e['address'] as Map?) ?? {}).cast<String, dynamic>();
      final alamat = _alamat(a);
      final extra = ((e['extratags'] as Map?) ?? {}).cast<String, dynamic>();
      out.add(PlaceInfo(
        id: 'osm-${e['osm_type']}-${e['osm_id']}',
        nama: nama,
        jenis: jenis,
        alamat: alamat.isEmpty ? 'Sekitar lokasi Anda' : alamat,
        lat: lat,
        lng: lng,
        harga: '',
        hargaNote: '',
        rating: 0,
        ulasan: 0,
        desc: '$jenis di sekitar lokasi Anda. Data peta OpenStreetMap.',
        contoh: false,
        jam: '${extra['opening_hours'] ?? ''}',
        telepon: '${extra['phone'] ?? extra['contact:phone'] ?? ''}',
        situs: '${extra['website'] ?? extra['contact:website'] ?? ''}',
        foto: _foto(extra),
        fasilitas: _fasilitas(extra),
      ));
    }
    return out;
  }

  /// Petakan respons Overpass jadi `PlaceInfo`; tanpa nama/jenis dikenal dibuang.
  static List<PlaceInfo> dariJson(dynamic body, double lat, double lng) {
    final els = ((body as Map)['elements'] as List?) ?? [];
    final out = <PlaceInfo>[];
    for (final raw in els) {
      final e = (raw as Map).cast<String, dynamic>();
      final t = ((e['tags'] as Map?) ?? {}).cast<String, dynamic>();
      final nama = '${t['name'] ?? ''}'.trim();
      if (nama.isEmpty) continue; // tanpa nama tak berguna di daftar
      final jenis = t['amenity'] == 'marketplace'
          ? 'Pasar'
          : _toko[t['shop']];
      if (jenis == null) continue;
      if (_namaTidakCocok(nama, jenis)) continue;
      final c = (e['center'] as Map?)?.cast<String, dynamic>();
      final plat = ((e['lat'] ?? c?['lat']) as num?)?.toDouble();
      final plng = ((e['lon'] ?? c?['lon']) as num?)?.toDouble();
      if (plat == null || plng == null) continue;
      final alamat = [
        [t['addr:street'], t['addr:housenumber']]
            .where((s) => s != null && '$s'.trim().isNotEmpty)
            .join(' '),
        t['addr:suburb'] ?? t['addr:village'],
        t['addr:city'],
        t['addr:postcode'],
      ].where((s) => s != null && '$s'.trim().isNotEmpty).join(', ');
      out.add(PlaceInfo(
        id: 'osm-${e['type']}-${e['id']}',
        nama: nama,
        jenis: jenis,
        alamat: alamat.isEmpty ? 'Sekitar lokasi Anda' : alamat,
        lat: plat,
        lng: plng,
        harga: '',
        hargaNote: '',
        rating: 0,
        ulasan: 0,
        desc: '$jenis di sekitar lokasi Anda. Data peta OpenStreetMap.',
        contoh: false,
        jam: '${t['opening_hours'] ?? ''}',
        telepon: '${t['phone'] ?? t['contact:phone'] ?? ''}',
        situs: '${t['website'] ?? t['contact:website'] ?? ''}',
        foto: _foto(t),
        fasilitas: _fasilitas(t),
      ));
    }
    return rapikan(out, lat, lng);
  }

  /// Buang dobel (nama + titik sama), urutkan terdekat, batasi 60.
  static List<PlaceInfo> rapikan(
      List<PlaceInfo> data, double lat, double lng) {
    final seen = <String>{};
    final out = data.where((p) {
      // Nama sama di lokasi lain tetap; node+way untuk tempat sama dibuang.
      final kunci = '${p.nama.toLowerCase()}|'
          '${p.lat.toStringAsFixed(4)}|${p.lng.toStringAsFixed(4)}';
      return seen.add(kunci);
    }).toList();
    // Terdekat dulu; radius 5 km cukup kecil untuk memakai selisih derajat.
    out.sort((a, b) => _d2(a, lat, lng).compareTo(_d2(b, lat, lng)));
    return out.take(60).toList();
  }

  static double _d2(PlaceInfo p, double lat, double lng) {
    final dy = p.lat - lat, dx = p.lng - lng;
    return dx * dx + dy * dy;
  }
}
