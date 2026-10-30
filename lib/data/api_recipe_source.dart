import '../core/api/api_client.dart';
import '../models/recipe.dart';

/// Sumber resep dari REST API backend MasakYuk.
/// GET /api/v1/resep        -> daftar terbit (publik)
/// GET /api/v1/resep?milik=saya -> semua resep milik akun yang login
/// GET /api/v1/resep/{id}   -> detail (bahan_resep, langkah_resep, kategori)
class ApiRecipeSource {
  final ApiClient api;
  ApiRecipeSource([ApiClient? api]) : api = api ?? ApiClient();

  Future<List<Recipe>> fetchAll() async {
    final index = await api.get('/api/v1/resep');
    return _details(index);
  }

  /// Resep milik sendiri, termasuk draf (butuh token).
  Future<List<Recipe>> fetchMine() async {
    final index = await api.get('/api/v1/resep', query: {'milik': 'saya'});
    return _details(index, mine: true);
  }

  Future<List<Recipe>> _details(dynamic index, {bool mine = false}) async {
    final items =
        ((index['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final details = await Future.wait(
      items.map((e) => api.get('/api/v1/resep/${e['id']}')),
    );
    return details
        .whereType<Map<String, dynamic>>()
        .map((j) => toRecipe(j, mine: mine))
        .toList();
  }

  Future<Recipe> fetchOne(String id) async {
    final j = await api.get('/api/v1/resep/$id');
    return toRecipe((j as Map).cast<String, dynamic>(), mine: true);
  }

  /// POST /api/v1/resep — tersimpan sebagai draf.
  Future<Recipe> create({
    required String judul,
    required String kategori,
    required List<String> bahan,
    required List<String> langkah,
    String deskripsi = '',
    int? porsi,
    int? waktuMasak,
    int? hargaResep,
  }) async {
    final res = await api.post(
      '/api/v1/resep',
      body: await _body(
        judul: judul,
        kategori: kategori,
        bahan: bahan,
        langkah: langkah,
        deskripsi: deskripsi,
        porsi: porsi,
        waktuMasak: waktuMasak,
        hargaResep: hargaResep,
      ),
    );
    return toRecipe((res as Map).cast<String, dynamic>(), mine: true);
  }

  /// PUT /api/v1/resep/{id} — ganti isi resep.
  Future<Recipe> update(
    String id, {
    required String judul,
    required String kategori,
    required List<String> bahan,
    required List<String> langkah,
    String deskripsi = '',
    int? porsi,
    int? waktuMasak,
    int? hargaResep,
  }) async {
    final res = await api.put(
      '/api/v1/resep/$id',
      body: await _body(
        judul: judul,
        kategori: kategori,
        bahan: bahan,
        langkah: langkah,
        deskripsi: deskripsi,
        porsi: porsi,
        waktuMasak: waktuMasak,
        hargaResep: hargaResep,
      ),
    );
    return toRecipe((res as Map).cast<String, dynamic>(), mine: true);
  }

  Future<Recipe> publish(String id) async {
    await api.post('/api/v1/resep/$id/terbit');
    return fetchOne(id);
  }

  Future<Recipe> tarik(String id) async {
    await api.post('/api/v1/resep/$id/tarik');
    return fetchOne(id);
  }

  Future<void> archive(String id) => api.delete('/api/v1/resep/$id');

  Future<Map<String, dynamic>> _body({
    required String judul,
    required String kategori,
    required List<String> bahan,
    required List<String> langkah,
    required String deskripsi,
    required int? porsi,
    required int? waktuMasak,
    required int? hargaResep,
  }) async {
    final kategoriId = await _kategoriId(kategori);
    return {
      'judul': judul,
      if (deskripsi.isNotEmpty) 'deskripsi': deskripsi,
      'porsi': ?porsi,
      'waktu_masak': ?waktuMasak,
      'harga_resep': ?hargaResep,
      if (kategoriId != null) 'kategori_ids': [kategoriId],
      'bahan': bahan.map(bahanPayload).toList(),
      'langkah': langkah.map((s) => {'instruksi': s}).toList(),
    };
  }

  // Daftar kategori cukup diambil sekali per sesi.
  Future<List<Map<String, dynamic>>>? _kategori;

  Future<int?> _kategoriId(String nama) async {
    final daftar = await (_kategori ??= _muatKategori());
    final n = nama.toLowerCase();
    for (final k in daftar) {
      if (k['nama'].toString().toLowerCase() == n) {
        return (k['id'] as num).toInt();
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _muatKategori() async {
    final data = await api.get('/api/v1/kategori-resep');
    return ((data as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// "2 siung bawang putih" -> {jumlah: 2, satuan: 'siung', nama: 'bawang putih'}
  Map<String, dynamic> bahanPayload(String teks) {
    final kata = teks.trim().split(RegExp(r'\s+'));
    num? jumlah;
    var satuan = '';
    var i = 0;
    if (kata.isNotEmpty) {
      jumlah = _nilai(kata.first);
      if (jumlah != null) i = 1;
    }
    if (i < kata.length && _satuan.contains(kata[i].toLowerCase())) {
      satuan = kata[i];
      i++;
    }
    final nama = kata.skip(i).join(' ').trim();
    return {
      'nama': nama.isEmpty ? teks.trim() : nama,
      'jumlah': ?jumlah,
      if (satuan.isNotEmpty) 'satuan': satuan,
    };
  }

  static const _satuan = {
    'gr', 'gram', 'kg', 'ml', 'l', 'liter', 'ons', 'sdm', 'sdt',
    'sendok', 'siung', 'butir', 'buah', 'batang', 'lembar', 'papan',
    'ruas', 'ekor', 'potong', 'bungkus', 'sachet', 'kaleng', 'piring',
    'mangkok', 'gelas', 'ikat', 'biji',
  };

  /// "2" -> 2, "0,5" -> 0.5, "1/2" -> 0.5
  num? _nilai(String s) {
    final p = s.split('/');
    if (p.length == 2) {
      final a = num.tryParse(p[0]);
      final b = num.tryParse(p[1]);
      return (a == null || b == null || b == 0) ? null : a / b;
    }
    return num.tryParse(s.replaceAll(',', '.'));
  }

  Recipe toRecipe(Map<String, dynamic> j, {bool mine = false}) {
    final bahan =
        ((j['bahan_resep'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final langkah = (((j['langkah_resep'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList())
      ..sort((a, b) =>
          ((a['nomor_langkah'] as num?) ?? 0)
              .compareTo((b['nomor_langkah'] as num?) ?? 0));
    final kategori = ((j['kategori_resep'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    final namaBahan = bahan
        .map((b) => ((b['bahan'] as Map?)?['nama'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final keywords = <String>{
      for (final n in namaBahan)
        ...n
            .toLowerCase()
            .split(RegExp(r'[^a-z]+'))
            .where((w) => w.length >= 3),
    }.toList();

    return Recipe(
      docId: j['id'].toString(),
      title: (j['judul'] ?? '-').toString(),
      category:
          kategori.isEmpty ? 'Lainnya' : kategori.first['nama'].toString(),
      tags: kategori.map((k) => k['slug'].toString()).toList(),
      ingredientsRaw: bahan.map(_bahanText).toList(),
      ingredientsKeywords: keywords,
      stepsList: langkah.map((l) => (l['instruksi'] ?? '').toString()).toList(),
      calories: null,
      proteins: null,
      fat: null,
      carbohydrate: null,
      hasNutrition: false,
      nutritionSource: 'missing',
      loves: 0,
      origin: mine ? 'custom' : 'system',
      isPublished: (j['status'] as String? ?? 'terbit') == 'terbit',
      ownerId: mine ? j['pemilik_id']?.toString() : null,
      description: (j['deskripsi'] ?? '').toString(),
      durationText:
          j['waktu_masak'] == null ? null : '${j['waktu_masak']} mnt',
      servings: j['porsi'] == null ? null : '${j['porsi']} Porsi',
      estCostManual: (j['harga_resep'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    );
  }

  String _bahanText(Map<String, dynamic> b) {
    final qty = _angka(b['jumlah']);
    final satuan = (b['satuan'] ?? '').toString();
    final nama = ((b['bahan'] as Map?)?['nama'] ?? '').toString();
    return [qty, satuan, nama].where((s) => s.isNotEmpty).join(' ');
  }

  /// "500.00" -> "500", "0.50" -> "0.5"
  String _angka(dynamic v) {
    if (v == null) return '';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }
}
