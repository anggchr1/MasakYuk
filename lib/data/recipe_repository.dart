import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/services/location_service.dart';
import '../core/services/places_service.dart';
import '../models/know.dart';
import '../models/recipe.dart';
import '../models/social.dart';
import 'api_recipe_source.dart';

/// Sumber data sementara: assets/sample_recipes.json (24 resep).
/// NANTI (M2): ganti _loadLocal dengan query Firestore:
///   recipes_master limit(20) + recipes where isPublished==true + milik uid.
/// Interface search/top3/rest TIDAK berubah.
class RecipeRepository extends ChangeNotifier {
  /// Satu ApiClient untuk semua request — token login ikut otomatis.
  final ApiClient api = ApiClient();
  late final ApiRecipeSource _apiResep = ApiRecipeSource(api);

  final List<Recipe> _system = [];
  final List<Recipe> _custom = [];
  /// Nama kategori -> slug API (urut dari server).
  final Map<String, String> kategori = {};
  int _halaman = 1;
  int _totalHalaman = 1;
  /// Total resep terbit di server (untuk teks "x dari y").
  int total = 0;
  bool habis = false;
  bool _memuatLagi = false;
  bool get memuatLagi => _memuatLagi;
  /// Halaman & total per kategori (pagination chip kategori).
  final Map<String, int> _halKat = {};
  final Map<String, int> _totalHalKat = {};
  final Map<String, int> _totalKat = {};
  final Set<String> _memuatKat = {};
  final Set<String> _favorites = {};
  final List<Map<String, dynamic>> _prices = [];
  final List<IngredientInfo> encyclopedia = [];
  /// Impor Wikipedia (bahan & masakan); cache lokal dibuat dari respons API.
  final List<IngredientInfo> _ensiklopediaServer = [];
  static const _kEnsiklopedia = 'ensiklopedia.cache';
  final List<PlaceInfo> places = [];
  final List<NotifItem> notifs = [];
  bool loaded = false;

  /// Diisi `main` untuk layar yang butuh login (mis. beri ulasan).
  VoidCallback? onNeedLogin;

  // Akun mock — NANTI: FirebaseAuth.currentUser (M2)
  String userName = 'Sobat MasakYuk';
  String userEmail = 'sobat@masakyuk.id';
  String? userAvatarUrl; // foto profil di Cloudinary; null = avatar bawaan

  List<Recipe> get customs => List.unmodifiable(_custom);
  bool isFavorite(String docId) => _favorites.contains(docId);

  /// True kalau konten Wikipedia sudah termuat (dari API atau cache).
  bool get ensiklopediaDaring => _ensiklopediaServer.isNotEmpty;

  /// Ensiklopedia tampil: kurasi lokal + impor Wikipedia (nama ganda dibuang).
  List<IngredientInfo> get ensiklopedia {
    final lokal = {for (final e in encyclopedia) e.nama.toLowerCase()};
    return [
      ...encyclopedia,
      ..._ensiklopediaServer
          .where((e) => !lokal.contains(e.nama.toLowerCase())),
    ];
  }

  List<Recipe> get favorites => [
        ..._system.where((r) => _favorites.contains(r.docId)),
        ..._custom.where((r) => _favorites.contains(r.docId)),
      ];

  /// Pool pencarian = resep publik + resep milik sendiri yang terbit.
  /// Resep sendiri didahulukan supaya tidak dobel dengan daftar publik.
  List<Recipe> get _pool {
    final mine = {for (final r in _custom) r.docId};
    return [
      ..._system.where((r) => !mine.contains(r.docId)),
      ..._custom.where((r) => r.isPublished),
    ];
  }

  /// Muat ulang resep milik akun yang login (termasuk draf).
  Future<void> muatResepMilikku() async {
    if (api.token == null) return;
    try {
      final hasil = await _apiResep.fetchMine();
      _custom
        ..clear()
        ..addAll(hasil);
      unawaited(_simpanCacheMilikku());
    } catch (e) {
      debugPrint('Gagal memuat resep milik sendiri: $e');
      await _muatCacheTersimpan();
    }
    notifyListeners();
  }

  /// Muat ulang resep publik (tanpa token) — dipakai setelah logout
  /// supaya resep yang baru diterbitkan tetap tampil untuk tamu.
  Future<void> muatUlangPublik() async {
    try {
      final hasil = await _apiResep.fetchAll();
      _system
        ..clear()
        ..addAll(hasil.resep);
      total = hasil.total;
      _totalHalaman = hasil.halamanTerakhir;
      _halaman = 1;
      habis = false;
      _halKat.clear();
      _totalHalKat.clear();
      _totalKat.clear();
      _memuatKat.clear();
      unawaited(muatLagi()); // tambah 1 halaman untuk tamu
    } catch (e) {
      debugPrint('Gagal memuat resep publik: $e');
    }
    notifyListeners();
  }

  /// Chip kategori: "Semua" + nama dari server.
  List<String> get chips => ['Semua', ...kategori.keys];

  /// Daftar kategori (untuk chip). Resepnya dimuat saat chip dibuka.
  Future<void> muatKategoriResep() async {
    try {
      final daftar = await _apiResep.fetchKategori();
      kategori
        ..clear()
        ..addEntries(daftar.map((k) =>
            MapEntry('${k['nama']}', '${k['slug']}')));
    } catch (e) {
      debugPrint('Gagal memuat kategori resep: $e');
    }
    notifyListeners();
  }

  /// Jumlah resep satu kategori di server (0 = belum dimuat).
  int totalKategori(String nama) => _totalKat[nama] ?? 0;

  bool memuatKategori(String nama) => _memuatKat.contains(nama);

  bool kategoriHabis(String nama) {
    final hal = _halKat[nama] ?? 0;
    return hal > 0 && hal >= (_totalHalKat[nama] ?? 1);
  }

  /// 15 resep terbaru satu kategori (halaman 1).
  Future<void> _muatKategori(String nama) async {
    final slug = kategori[nama];
    if (slug == null || (_halKat[nama] ?? 0) > 0) return;
    _memuatKat.add(nama);
    notifyListeners();
    try {
      final hasil = await _apiResep.fetchAll(kategori: slug);
      _halKat[nama] = 1;
      _totalHalKat[nama] = hasil.halamanTerakhir;
      _totalKat[nama] = hasil.total;
      _gabung(hasil.resep);
    } catch (e) {
      debugPrint('Gagal memuat kategori $nama: $e');
    }
    _memuatKat.remove(nama);
    notifyListeners();
  }

  /// Tambah 1 halaman (15 resep) pada satu kategori.
  Future<void> muatKategoriLagi(String nama) async {
    final slug = kategori[nama];
    if (slug == null || _memuatKat.contains(nama)) return;
    if ((_halKat[nama] ?? 0) == 0) {
      // Halaman 1 saja saat chip dibuka; sisanya lewat tombol.
      await _muatKategori(nama);
      return;
    }
    var hal = _halKat[nama] ?? 0;
    final totalHal = _totalHalKat[nama] ?? 1;
    if (hal == 0 || hal >= totalHal) return;
    _memuatKat.add(nama);
    notifyListeners();
    try {
      final hasil =
          await _apiResep.fetchAll(kategori: slug, page: hal + 1);
      hal++;
      _gabung(hasil.resep);
      _halKat[nama] = hal;
      _totalKat[nama] = hasil.total;
      _totalHalKat[nama] = hasil.halamanTerakhir;
    } catch (e) {
      debugPrint('Gagal memuat kategori $nama: $e');
    }
    _memuatKat.remove(nama);
    notifyListeners();
  }

  /// Muat 1 halaman (15 resep) berikutnya saat tombol ditekan.
  Future<void> muatLagi() async {
    if (habis || _memuatLagi || _halaman >= _totalHalaman) return;
    _memuatLagi = true;
    notifyListeners();
    try {
      final hasil = await _apiResep.fetchAll(page: _halaman + 1);
      _halaman++;
      _gabung(hasil.resep);
      total = hasil.total;
      _totalHalaman = hasil.halamanTerakhir;
      if (_halaman >= _totalHalaman) habis = true;
    } catch (e) {
      debugPrint('Gagal memuat resep berikutnya: $e');
    }
    _memuatLagi = false;
    notifyListeners();
  }

  void _gabung(Iterable<Recipe> baru) {
    final ada = {for (final r in _system) r.docId};
    _system.addAll(baru.where((r) => ada.add(r.docId)));
  }

  Future<void> load() async {
    if (loaded) return;
    Future<List> loadJson(String p) async =>
        (json.decode(await rootBundle.loadString(p)) as List);
    // Resep: dari backend (API sumber utama). Tanpa fallback lokal.
    try {
      final hasil = await _apiResep.fetchAll();
      _system.addAll(hasil.resep);
      total = hasil.total;
      _totalHalaman = hasil.halamanTerakhir;
    } catch (e) {
      debugPrint('Gagal memuat resep dari API: $e');
      await _muatCacheTersimpan();
    }
    await muatKategoriResep();
    final pr =
        (await loadJson('assets/prices.json')).cast<Map<String, dynamic>>();
    _prices.addAll(pr);
    final en = (await loadJson('assets/encyclopedia.json'))
        .cast<Map<String, dynamic>>();
    encyclopedia.addAll(en.map(IngredientInfo.fromJson));
    await _muatCacheEnsiklopedia();
    loaded = true;
    notifyListeners();
    // Tambah 1 halaman di latar agar tombol pertama terasa instan.
    unawaited(muatLagi());
    muatEnsiklopedia(); // jaringan; gagal = pakai cache/assets
  }

  DateTime? _tempatWaktu;
  double? _tempatLat;
  double? _tempatLng;

  /// Isi `places` dengan tempat makan/pasar terdekat (OpenStreetMap).
  /// Nominatim dulu (cepat), toko dari Overpass menyusul di latar.
  Future<void> muatTempatSekitar(double lat, double lng,
      {bool paksa = false}) async {
    final w = _tempatWaktu;
    // Cache hanya berlaku untuk titik yang sama (±100 m); kalau user pindah,
    // tempat lama tidak boleh dipertahankan.
    final samaTitik = _tempatLat != null &&
        _tempatLng != null &&
        (lat - _tempatLat!).abs() < 0.001 &&
        (lng - _tempatLng!).abs() < 0.001;
    if (!paksa &&
        w != null &&
        samaTitik &&
        places.isNotEmpty &&
        DateTime.now().difference(w) < const Duration(minutes: 10)) {
      return; // hindari 429 saat layar dibuka-tutup berulang
    }
    List<PlaceInfo> dekat;
    try {
      dekat = await PlacesService.sekitar(lat, lng);
    } catch (_) {
      dekat = await PlacesService.toko(lat, lng);
    }
    places
      ..clear()
      ..addAll(dekat);
    _tempatWaktu = DateTime.now();
    _tempatLat = lat;
    _tempatLng = lng;
    notifyListeners();
    if (dekat.isNotEmpty) unawaited(_lengkapiTempat(lat, lng));
  }

  /// Ambil lokasi awal + tempat sekitar agar Home & peta langsung terisi.
  Future<void> siapkanTempatAwal() async {
    try {
      final r = await LocationService.current();
      await muatTempatSekitar(r.pos.latitude, r.pos.longitude);
    } catch (e) {
      debugPrint('Lokasi awal belum tersedia: $e');
    }
  }

  /// Tambahkan pasar/toko dari Overpass tanpa mengganggu daftar yang tampil.
  Future<void> _lengkapiTempat(double lat, double lng) async {
    try {
      final toko = await PlacesService.toko(lat, lng);
      final ada = {for (final p in places) _kunciTempat(p)};
      final baru = toko.where((p) => ada.add(_kunciTempat(p))).toList();
      if (baru.isEmpty) return;
      places
        ..addAll(baru)
        ..sort((a, b) =>
            _jarak2(a, lat, lng).compareTo(_jarak2(b, lat, lng)));
      if (places.length > 80) places.removeRange(80, places.length);
      notifyListeners();
    } catch (_) {
      // Overpass sibuk: daftar dari Nominatim tetap dipakai.
    }
  }

  static String _kunciTempat(PlaceInfo p) => '${p.nama.toLowerCase()}|'
      '${p.lat.toStringAsFixed(4)}|${p.lng.toStringAsFixed(4)}';

  static double _jarak2(PlaceInfo p, double lat, double lng) {
    final dy = p.lat - lat, dx = p.lng - lng;
    return dx * dx + dy * dy;
  }

  /// Favorit + resep sendiri disimpan agar tetap bisa dibuka tanpa internet.
  static const _kFavoritCache = 'resep.favorit.cache';
  static const _kMilikkuCache = 'resep.milikku.cache';

  Future<void> _simpanCacheFavorit() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await p.setString(_kFavoritCache,
          json.encode(favorites.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('Gagal menyimpan cache favorit: $e');
    }
  }

  Future<void> _simpanCacheMilikku() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await p.setString(_kMilikkuCache,
          json.encode(_custom.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('Gagal menyimpan cache resep sendiri: $e');
    }
  }

  /// Isi ulang favorit + resep sendiri dari cache saat API tak terjangkau.
  Future<void> _muatCacheTersimpan() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final milik = (json.decode(p.getString(_kMilikkuCache) ?? '[]') as List)
          .cast<Map<String, dynamic>>()
          .map(Recipe.fromJson)
          .toList();
      final ada = {for (final r in _custom) r.docId};
      _custom.addAll(milik.where((r) => ada.add(r.docId)));
      final favorit =
          (json.decode(p.getString(_kFavoritCache) ?? '[]') as List)
              .cast<Map<String, dynamic>>()
              .map(Recipe.fromJson)
              .toList();
      final punyaSendiri = {for (final r in _custom) r.docId};
      _gabung(favorit.where((r) => !punyaSendiri.contains(r.docId)));
      _favorites.addAll(favorit.map((r) => r.docId));
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat cache resep: $e');
    }
  }

  Future<void> _hapusCacheTersimpan() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await p.remove(_kFavoritCache);
      await p.remove(_kMilikkuCache);
    } catch (e) {
      debugPrint('Gagal menghapus cache resep: $e');
    }
  }

  /// Baca snapshot ensiklopedia terakhir dari perangkat (mode offline).
  Future<void> _muatCacheEnsiklopedia() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final s = p.getString(_kEnsiklopedia);
      if (s == null) return;
      _isiEnsiklopedia(ensiklopediaDariRespons(json.decode(s)));
    } catch (e) {
      debugPrint('Gagal memuat cache ensiklopedia: $e');
    }
  }

  /// Segarkan dari server, lalu simpan supaya bisa dibuka tanpa internet.
  /// Dipanggil saat app mulai dan setiap kali layar Ensiklopedia dibuka.
  Future<void> muatEnsiklopedia() async {
    try {
      final res = await api.get('/api/v1/ensiklopedia');
      final data = ensiklopediaDariRespons(res);
      if (data.isEmpty) return;
      _isiEnsiklopedia(data);
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      await p.setString(_kEnsiklopedia, json.encode(data));
    } catch (e) {
      debugPrint('Ensiklopedia mode offline: $e');
    }
  }

  void _isiEnsiklopedia(List<IngredientInfo> data) {
    _ensiklopediaServer
      ..clear()
      ..addAll(data);
    notifyListeners();
  }

  // ---------- Budget: jumlahkan harga bahan yang cocok ----------
  ({int min, int max, bool complete}) estCost(Recipe r) {
    if (r.estCostManual != null) {
      final v = r.estCostManual!;
      return (
        min: (v * 0.75).round(),
        max: (v * 1.25).round(),
        complete: true
      );
    }
    final keys = r.ingredientsKeywords.toSet();
    var sum = 0;
    var hit = 0;
    for (final p in _prices) {
      final need = (p['k'] as String).split(' ');
      if (need.every(keys.contains)) {
        sum += (p['rp'] as num).toInt();
        hit++;
      }
    }
    if (hit < 3) return (min: 0, max: 0, complete: false);
    return (
      min: (sum * 0.75).round(),
      max: (sum * 1.25).round(),
      complete: true
    );
  }

  /// Resep dalam range ±25% budget, termurah dulu, tak lengkap di belakang.
  List<Recipe> budgetSearch(int budget) {
    final lo = (budget * 0.75).round();
    final hi = (budget * 1.25).round();
    final ok = <Recipe>[];
    final partial = <Recipe>[];
    for (final r in _pool) {
      final e = estCost(r);
      if (!e.complete) {
        partial.add(r);
        continue;
      }
      if (e.min <= hi && e.max >= lo) ok.add(r);
    }
    ok.sort((a, b) =>
        estCost(a).min.compareTo(estCost(b).min));
    return [...ok, ...partial];
  }

  /// Rincian bahan berbiaya (untuk kartu budget).
  List<MapEntry<String, int>> priceBreakdown(Recipe r) {
    final keys = r.ingredientsKeywords.toSet();
    final out = <MapEntry<String, int>>[];
    for (final p in _prices) {
      final need = (p['k'] as String).split(' ');
      if (need.every(keys.contains)) {
        out.add(MapEntry(
            p['nama'] as String, (p['rp'] as num).toInt()));
      }
    }
    return out;
  }

  Recipe? findById(String id) {
    for (final r in [..._system, ..._custom]) {
      if (r.docId == id) return r;
    }
    return null;
  }

  List<Recipe> searchTitle(String q) {
    final s = q.toLowerCase();
    if (s.isEmpty) return [];
    return _pool.where((r) => r.title.toLowerCase().contains(s)).toList();
  }

  // ---------- Ulasan & rating (tersimpan di server) ----------

  /// Ulasan + ringkasan rating sebuah resep.
  Future<Map<String, dynamic>> ulasanResep(String docId) async =>
      (await api.get('/api/v1/resep/$docId/komentar') as Map)
          .cast<String, dynamic>();

  Future<Map<String, dynamic>> beriNilai(String docId, int skor) async =>
      (await api.post('/api/v1/resep/$docId/nilai', body: {'skor': skor})
              as Map)
          .cast<String, dynamic>();

  /// Satu ulasan per akun per resep (aturan server).
  Future<Map<String, dynamic>> kirimUlasan(String docId, String isi) async =>
      (await api.post('/api/v1/resep/$docId/komentar', body: {'isi': isi})
              as Map)
          .cast<String, dynamic>();

  // ---------- Notifikasi in-app ----------
  int get unreadCount => notifs.where((n) => !n.read).length;

  Timer? _pantauNotif;

  /// Segarkan notifikasi tiap 45 detik selama login, supaya komentar baru
  /// muncul tanpa push FCM (server mungkin belum punya kredensial Firebase).
  void mulaiPantauNotifikasi() {
    _pantauNotif?.cancel();
    if (api.token == null) return;
    _pantauNotif = Timer.periodic(const Duration(seconds: 45), (_) {
      if (api.token == null) {
        _pantauNotif?.cancel();
        return;
      }
      muatNotifikasi();
    });
  }

  /// Ambil notifikasi komentar dari server (butuh login).
  Future<void> muatNotifikasi() async {
    if (api.token == null) {
      notifs.clear();
      notifyListeners();
      return;
    }
    try {
      final res = await api.get('/api/v1/notifikasi');
      final list = ((res is Map ? res['data'] : res) as List?) ?? const [];
      notifs
        ..clear()
        ..addAll(list
            .cast<Map<String, dynamic>>()
            .map(NotifItem.dariServer));
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat notifikasi: $e');
    }
  }

  Future<void> markRead(String id) async {
    for (final n in notifs) {
      if (n.id == id) n.read = true;
    }
    notifyListeners();
    try {
      await api.post('/api/v1/notifikasi/$id/baca');
    } catch (e) {
      debugPrint('Gagal menandai notifikasi dibaca: $e');
    }
  }

  Future<void> markAllRead() async {
    for (final n in notifs) {
      n.read = true;
    }
    notifyListeners();
    try {
      await api.post('/api/v1/notifikasi/baca-semua');
    } catch (e) {
      debugPrint('Gagal menandai semua notifikasi dibaca: $e');
    }
  }

  /// Daftarkan token FCM perangkat ke akun yang sedang login.
  Future<void> daftarkanPerangkat(String token) async {
    if (api.token == null) return;
    try {
      await api.post('/api/v1/perangkat', body: {'token': token});
    } catch (e) {
      debugPrint('Gagal mendaftarkan perangkat: $e');
    }
  }

  /// Hasil urut skor tertinggi. top3 = 3 utama, rest = "lihat lainnya".
  ({List<Recipe> top3, List<Recipe> rest}) search(Set<String> inputs) {
    final scored = _pool
        .map((r) => MapEntry(r, r.matchScore(inputs)))
        .where((e) => inputs.isEmpty || e.value > 0)
        .toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : b.key.loves.compareTo(a.key.loves);
      });
    final ordered = scored.map((e) => e.key).toList();
    return (
      top3: ordered.take(3).toList(),
      rest: ordered.skip(3).take(17).toList(),
    );
  }

  List<Recipe> byTag(String tag) =>
      _pool.where((r) => r.tags.contains(tag)).toList();

  /// Semua resep yang termuat (publik + milik sendiri yang terbit).
  List<Recipe> get semua => List.unmodifiable(_pool);

  /// Filter chip kategori: cocokkan slug API (`tags`) atau nama kategori.
  List<Recipe> byDisplayCategory(String c) {
    final slug = kategori[c];
    if (slug != null) {
      return _pool
          .where((r) => r.tags.contains(slug) || r.category == c)
          .toList();
    }
    // Fallback bila daftar kategori server belum termuat.
    switch (c) {
      case 'Sarapan':
        return byTag('sarapan');
      case 'Cepat & Mudah':
        return byTag('cepat');
      case 'Pedas':
        return byTag('pedas');
      case 'Ayam & Daging':
        return _pool
            .where((r) =>
                r.category == 'Unggas' ||
                r.category == 'Daging')
            .toList();
      case 'Seafood':
        return _pool
            .where((r) => r.category == 'Seafood')
            .toList();
      case 'Sayuran':
        return _pool
            .where((r) => r.category == 'Nabati')
            .toList();
      case 'Nusantara':
      default:
        return List.of(_pool);
    }
  }

  void toggleFavorite(String docId) {
    final hapus = _favorites.remove(docId);
    if (!hapus) _favorites.add(docId);
    notifyListeners();
    unawaited(_simpanCacheFavorit());
    if (api.token != null) _kirimFavorit(docId, hapus);
  }

  /// Favorit milik akun yang login, dimuat sekali per sesi.
  Future<void> muatFavorit() async {
    if (api.token == null) return;
    try {
      final ids = <String>[];
      for (var page = 1;; page++) {
        final res = await api.get('/api/v1/favorit', query: {'page': '$page'});
        final data =
            ((res['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
        ids.addAll(data.map((e) => (e['resep_id'] ?? '').toString()));
        final last = (res['last_page'] as num?)?.toInt() ?? 1;
        if (page >= last) break;
      }
      _favorites
        ..clear()
        ..addAll(ids);
      unawaited(_simpanCacheFavorit());
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat favorit: $e');
      await _muatCacheTersimpan();
    }
  }

  /// Simpan/hapus favorit di server; lokal dikembalikan bila server menolak.
  Future<void> _kirimFavorit(String docId, bool hapus) async {
    try {
      if (hapus) {
        await api.delete('/api/v1/favorit/$docId');
      } else {
        await api.post('/api/v1/favorit',
            body: {'resep_id': int.tryParse(docId)});
      }
    } catch (e) {
      if (hapus) {
        _favorites.add(docId);
      } else {
        _favorites.remove(docId);
      }
      notifyListeners();
      debugPrint('Gagal menyinkronkan favorit: $e');
      unawaited(_simpanCacheFavorit());
    }
  }

  /// Beri tahu UI setelah nama/foto profil diganti dari layar Profil.
  void profilDiperbarui() => notifyListeners();

  /// Unggah foto (sudah dikompres di sisi pemilih foto) ke Cloudinary
  /// lewat backend. Hasil: id media untuk disimpan + URL untuk ditampilkan.
  Future<({int id, String url})> uploadFoto(
    List<int> bytes, {
    String filename = 'foto.jpg',
  }) async {
    final res = (await api.upload('/api/v1/media',
            bytes: bytes, filename: filename)
        as Map)
        .cast<String, dynamic>();
    return (
      id: (res['id'] as num).toInt(),
      url: (res['url'] ?? '').toString(),
    );
  }

  /// Simpan resep baru ke akun yang login; terbitkan bila [publish].
  Future<void> addCustom({
    required String title,
    required List<String> kategori,
    required List<RecipeIngredient> bahan,
    required List<RecipeStep> langkah,
    required bool publish,
    String description = '',
    int? porsi,
    int? waktuMasak,
    int? estCostManual,
    int? gambarUtamaId,
  }) async {
    var r = await _apiResep.create(
      judul: title,
      kategoriNama: kategori,
      bahan: bahan,
      langkah: langkah,
      deskripsi: description,
      porsi: porsi,
      waktuMasak: waktuMasak,
      hargaResep: estCostManual,
      gambarUtamaId: gambarUtamaId,
    );
    if (publish) r = await _apiResep.publish(r.docId);
    _custom.insert(0, r);
    notifyListeners();
  }

  /// Ubah resep sendiri (dari menu Kelola).
  Future<void> updateCustom(
    String docId, {
    required String title,
    required List<String> kategori,
    required List<RecipeIngredient> bahan,
    required List<RecipeStep> langkah,
    required bool publish,
    String description = '',
    int? porsi,
    int? waktuMasak,
    int? estCostManual,
    int? gambarUtamaId,
  }) async {
    var r = await _apiResep.update(
      docId,
      judul: title,
      kategoriNama: kategori,
      bahan: bahan,
      langkah: langkah,
      deskripsi: description,
      porsi: porsi,
      waktuMasak: waktuMasak,
      hargaResep: estCostManual,
      gambarUtamaId: gambarUtamaId,
    );
    if (publish != r.isPublished) {
      r = publish
          ? await _apiResep.publish(docId)
          : await _apiResep.tarik(docId);
    }
    final i = _custom.indexWhere((r) => r.docId == docId);
    if (i < 0) {
      _custom.insert(0, r);
    } else {
      _custom[i] = r;
    }
    notifyListeners();
    unawaited(_simpanCacheMilikku());
  }

  /// Hapus dari koleksi = arsipkan di server.
  Future<void> deleteCustom(String docId) async {
    await _apiResep.archive(docId);
    _custom.removeWhere((r) => r.docId == docId);
    _favorites.remove(docId);
    notifyListeners();
    unawaited(_simpanCacheMilikku());
    unawaited(_simpanCacheFavorit());
  }

  /// Tarik jadi draf / terbitkan lagi.
  Future<void> togglePublish(String docId) async {
    final i = _custom.indexWhere((r) => r.docId == docId);
    if (i < 0) return;
    _custom[i] = _custom[i].isPublished
        ? await _apiResep.tarik(docId)
        : await _apiResep.publish(docId);
    notifyListeners();
    unawaited(_simpanCacheMilikku());
  }

  void logout() {
    _pantauNotif?.cancel();
    _pantauNotif = null;
    _custom.clear();
    _favorites.clear();
    notifs.clear();
    userAvatarUrl = null;
    unawaited(_hapusCacheTersimpan());
    notifyListeners();
  }
}
