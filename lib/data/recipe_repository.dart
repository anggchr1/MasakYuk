import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
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
    } catch (e) {
      debugPrint('Gagal memuat resep milik sendiri: $e');
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
        ..addAll(hasil);
    } catch (e) {
      debugPrint('Gagal memuat resep publik: $e');
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (loaded) return;
    Future<List> loadJson(String p) async =>
        (json.decode(await rootBundle.loadString(p)) as List);
    // Resep: dari backend (API sumber utama). Tanpa fallback lokal.
    try {
      _system.addAll(await _apiResep.fetchAll());
    } catch (e) {
      debugPrint('Gagal memuat resep dari API: $e');
    }
    final pr =
        (await loadJson('assets/prices.json')).cast<Map<String, dynamic>>();
    _prices.addAll(pr);
    final en = (await loadJson('assets/encyclopedia.json'))
        .cast<Map<String, dynamic>>();
    encyclopedia.addAll(en.map(IngredientInfo.fromJson));
    final pl =
        (await loadJson('assets/places.json')).cast<Map<String, dynamic>>();
    places.addAll(pl.map(PlaceInfo.fromJson));
    await _muatCacheEnsiklopedia();
    loaded = true;
    notifyListeners();
    muatEnsiklopedia(); // jaringan; gagal = pakai cache/assets
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

  /// Filter chip kategori ala desain v2 (nama tampilan → data).
  List<Recipe> byDisplayCategory(String c) {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat favorit: $e');
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
    required String category,
    required List<String> ingredients,
    required List<String> steps,
    required bool publish,
    String description = '',
    String? durationText,
    String? servings,
    int? estCostManual,
    int? gambarUtamaId,
  }) async {
    var r = await _apiResep.create(
      judul: title,
      kategori: category,
      bahan: ingredients,
      langkah: steps,
      deskripsi: description,
      porsi: _angkaAwal(servings),
      waktuMasak: _angkaAwal(durationText),
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
    required String category,
    required List<String> ingredients,
    required List<String> steps,
    required bool publish,
    String description = '',
    String? durationText,
    String? servings,
    int? estCostManual,
    int? gambarUtamaId,
  }) async {
    var r = await _apiResep.update(
      docId,
      judul: title,
      kategori: category,
      bahan: ingredients,
      langkah: steps,
      deskripsi: description,
      porsi: _angkaAwal(servings),
      waktuMasak: _angkaAwal(durationText),
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
  }

  /// Arsipkan draf lebih tua dari [days] hari. Kembalikan jumlah terarsip.
  Future<int> purgeOldDrafts(int days) async {
    final cut =
        DateTime.now().subtract(Duration(days: days));
    final doomed = _custom
        .where((r) =>
            !r.isPublished &&
            r.createdAt != null &&
            r.createdAt!.isBefore(cut))
        .toList();
    for (final r in doomed) {
      await _apiResep.archive(r.docId);
      _custom.remove(r);
      _favorites.remove(r.docId);
    }
    if (doomed.isNotEmpty) notifyListeners();
    return doomed.length;
  }

  /// Hapus dari koleksi = arsipkan di server.
  Future<void> deleteCustom(String docId) async {
    await _apiResep.archive(docId);
    _custom.removeWhere((r) => r.docId == docId);
    _favorites.remove(docId);
    notifyListeners();
  }

  /// Tarik jadi draf / terbitkan lagi.
  Future<void> togglePublish(String docId) async {
    final i = _custom.indexWhere((r) => r.docId == docId);
    if (i < 0) return;
    _custom[i] = _custom[i].isPublished
        ? await _apiResep.tarik(docId)
        : await _apiResep.publish(docId);
    notifyListeners();
  }

  /// "35 mnt" / "4 orang" -> 35 / 4
  int? _angkaAwal(String? s) =>
      s == null ? null : int.tryParse(RegExp(r'\d+').stringMatch(s) ?? '');

  void logout() {
    _custom.clear();
    _favorites.clear();
    notifs.clear();
    userAvatarUrl = null;
    notifyListeners();
  }
}
