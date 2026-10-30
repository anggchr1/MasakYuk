import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
  final List<PlaceInfo> places = [];
  final Map<String, List<CommentItem>> _comments = {};
  final Map<String, Map<String, int>> _ratings = {};
  final List<NotifItem> notifs = [];
  bool loaded = false;

  // Akun mock — NANTI: FirebaseAuth.currentUser (M2)
  String userName = 'Sobat MasakYuk';
  String userEmail = 'sobat@masakyuk.id';

  List<Recipe> get customs => List.unmodifiable(_custom);
  bool isFavorite(String docId) => _favorites.contains(docId);

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
    notifs.addAll([
      NotifItem(
        id: 'n0',
        kind: 'sistem',
        title: 'Selamat datang di MasakYuk!',
        desc: 'Cari resep dari bahan kulkasmu, lalu simpan favoritmu.',
        at: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NotifItem(
        id: 'n1',
        kind: 'sistem',
        title: 'Tips Dapur Nusantara',
        desc: 'Simpan bumbu marinasi minimal 20 menit agar lebih meresap.',
        at: DateTime.now().subtract(const Duration(days: 1)),
        read: true,
      ),
    ]);
    loaded = true;
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

  // ---------- Komentar & rating (1 user 1 rating aktif) ----------
  List<CommentItem> commentsFor(String docId) =>
      List.unmodifiable(_comments[docId] ?? []);

  void addComment(String docId, String text) {
    final list = _comments.putIfAbsent(docId, () => []);
    list.add(CommentItem(
        user: userName, text: text, at: DateTime.now()));
    notifyListeners();
  }

  void setRating(String docId, int stars, String title) {
    final m = _ratings.putIfAbsent(docId, () => {});
    m[userName] = stars.clamp(1, 5);
    pushNotif(
      kind: 'rating',
      title: 'Bintang $stars untuk "$title"',
      desc: 'Terima kasih atas penilaianmu!',
      recipeId: docId,
    );
    notifyListeners();
  }

  double avgRating(String docId) {
    final m = _ratings[docId];
    if (m == null || m.isEmpty) return 0;
    return m.values.reduce((a, b) => a + b) / m.length;
  }

  int ratingCount(String docId) => _ratings[docId]?.length ?? 0;
  int myRating(String docId) => _ratings[docId]?[userName] ?? 0;

  // ---------- Notifikasi in-app ----------
  int get unreadCount => notifs.where((n) => !n.read).length;

  void pushNotif({
    required String kind,
    required String title,
    required String desc,
    String? recipeId,
  }) {
    notifs.insert(
        0,
        NotifItem(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          kind: kind,
          title: title,
          desc: desc,
          at: DateTime.now(),
          recipeId: recipeId,
        ));
    notifyListeners();
  }

  void markRead(String id) {
    for (final n in notifs) {
      if (n.id == id) n.read = true;
    }
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifs) {
      n.read = true;
    }
    notifyListeners();
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
    if (!_favorites.remove(docId)) _favorites.add(docId);
    notifyListeners();
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
    String? difficulty,
    String? servings,
    int? estCostManual,
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
    );
    if (publish) r = await _apiResep.publish(r.docId);
    _custom.insert(0, r);
    pushNotif(
      kind: 'sistem',
      title: publish ? 'Resep Diterbitkan!' : 'Draf tersimpan',
      desc: publish
          ? 'Karyamu kini bisa ditemukan pengguna lain.'
          : 'Lanjutkan lagi kapan pun dari Resep Saya.',
    );
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
    String? difficulty,
    String? servings,
    int? estCostManual,
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
    notifyListeners();
  }
}
