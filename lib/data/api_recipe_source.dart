import '../core/api/api_client.dart';
import '../models/recipe.dart';

/// Sumber resep dari REST API backend MasakYuk.
/// GET /api/v1/resep        -> daftar terbit (publik)
/// GET /api/v1/resep?milik=saya -> semua resep milik akun yang login
/// GET /api/v1/resep/{id}   -> detail (bahan_resep, langkah_resep, kategori)
class ApiRecipeSource {
  final ApiClient api;
  ApiRecipeSource([ApiClient? api]) : api = api ?? ApiClient();

  /// [kategori] = slug kategori (mis. `ayam`); [page] mulai dari 1.
  /// Mengembalikan juga total & jumlah halaman untuk teks "x dari y".
  Future<({List<Recipe> resep, int total, int halamanTerakhir})> fetchAll({
    int page = 1,
    String? kategori,
  }) async {
    final index = await api.get('/api/v1/resep', query: {
      if (page > 1) 'page': '$page',
      'kategori': ?kategori,
    });
    return (
      resep: _list(index),
      total: (index['total'] as num?)?.toInt() ?? 0,
      halamanTerakhir: (index['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  /// Daftar kategori dari server (id, nama, slug, jumlah_terbit).
  Future<List<Map<String, dynamic>>> fetchKategori() => _muatKategori();

  /// Resep milik sendiri, termasuk draf & terbit (butuh token).
  Future<List<Recipe>> fetchMine() async {
    final index = await api.get('/api/v1/resep', query: {'milik': 'saya'});
    return _list(index, mine: true);
  }

  /// Satu request list sudah membawa bahan/langkah; tanpa N+1 detail.
  List<Recipe> _list(dynamic index, {bool mine = false}) {
    final items =
        ((index['data'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return items.map((e) => toRecipe(e, mine: mine)).toList();
  }

  Future<Recipe> fetchOne(String id) async {
    final j = await api.get('/api/v1/resep/$id');
    return toRecipe((j as Map).cast<String, dynamic>(), mine: true);
  }

  /// POST /api/v1/resep — tersimpan sebagai draf.
  Future<Recipe> create({
    required String judul,
    required List<String> kategoriNama,
    required List<RecipeIngredient> bahan,
    required List<RecipeStep> langkah,
    String deskripsi = '',
    int? porsi,
    int? waktuMasak,
    int? hargaResep,
    int? gambarUtamaId,
  }) async {
    final res = await api.post(
      '/api/v1/resep',
      body: await _body(
        judul: judul,
        kategoriNama: kategoriNama,
        bahan: bahan,
        langkah: langkah,
        deskripsi: deskripsi,
        porsi: porsi,
        waktuMasak: waktuMasak,
        hargaResep: hargaResep,
        gambarUtamaId: gambarUtamaId,
      ),
    );
    return toRecipe((res as Map).cast<String, dynamic>(), mine: true);
  }

  /// PUT /api/v1/resep/{id} — ganti isi resep.
  Future<Recipe> update(
    String id, {
    required String judul,
    required List<String> kategoriNama,
    required List<RecipeIngredient> bahan,
    required List<RecipeStep> langkah,
    String deskripsi = '',
    int? porsi,
    int? waktuMasak,
    int? hargaResep,
    int? gambarUtamaId,
  }) async {
    final res = await api.put(
      '/api/v1/resep/$id',
      body: await _body(
        judul: judul,
        kategoriNama: kategoriNama,
        bahan: bahan,
        langkah: langkah,
        deskripsi: deskripsi,
        porsi: porsi,
        waktuMasak: waktuMasak,
        hargaResep: hargaResep,
        gambarUtamaId: gambarUtamaId,
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
    required List<String> kategoriNama,
    required List<RecipeIngredient> bahan,
    required List<RecipeStep> langkah,
    required String deskripsi,
    required int? porsi,
    required int? waktuMasak,
    required int? hargaResep,
    int? gambarUtamaId,
  }) async {
    final daftar = await (_kategori ??= _muatKategori());
    final idKategori = <int>[];
    final kategoriBaru = <String>[];
    for (final nama in kategoriNama) {
      final cari = nama.trim().toLowerCase();
      if (cari.isEmpty) continue;
      Map<String, dynamic>? ada;
      for (final k in daftar) {
        if (k['nama'].toString().toLowerCase() == cari) {
          ada = k;
          break;
        }
      }
      if (ada == null) {
        kategoriBaru.add(nama.trim());
      } else {
        idKategori.add((ada['id'] as num).toInt());
      }
    }

    return {
      'judul': judul,
      if (deskripsi.isNotEmpty) 'deskripsi': deskripsi,
      'porsi': ?porsi,
      'waktu_masak': ?waktuMasak,
      'harga_resep': ?hargaResep,
      'gambar_utama_id': ?gambarUtamaId,
      if (idKategori.isNotEmpty) 'kategori_ids': idKategori,
      if (kategoriBaru.isNotEmpty) 'kategori_namas': kategoriBaru,
      'bahan': bahan
          .map((b) => {
                'nama': b.nama,
                if (b.jumlah.isNotEmpty) 'jumlah': b.jumlah,
                if (b.satuan.isNotEmpty) 'satuan': b.satuan,
                if (b.grup.isNotEmpty) 'grup': b.grup,
              })
          .toList(),
      'langkah': langkah
          .map((l) => {
                'instruksi': l.instruksi,
                'durasi_menit': l.durasiMenit,
                'durasi_detik': l.durasiDetik,
                for (var i = 0; i < l.gambarIds.length && i < 3; i++)
                  'gambar_id_${i + 1}': l.gambarIds[i],
              })
          .toList(),
    };
  }

  // Daftar kategori cukup diambil sekali per sesi.
  Future<List<Map<String, dynamic>>>? _kategori;

  Future<List<Map<String, dynamic>>> _muatKategori() async {
    final data = await api.get('/api/v1/kategori-resep');
    return ((data as List?) ?? const []).cast<Map<String, dynamic>>();
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

    final bahanDetail = bahan
        .map((b) => RecipeIngredient(
              nama: ((b['bahan'] as Map?)?['nama'] ?? '').toString(),
              jumlah: _angka(b['jumlah']),
              satuan: (b['satuan'] ?? '').toString(),
              grup: (b['grup'] ?? '').toString(),
            ))
        .where((b) => b.nama.isNotEmpty)
        .toList();

    final langkahDetail = langkah.map((l) {
      final foto = [l['gambar'], l['gambar2'], l['gambar3']]
          .whereType<Map>()
          .toList();
      return RecipeStep(
        instruksi: (l['instruksi'] ?? '').toString(),
        durasiMenit: _toInt(l['durasi_menit']) ?? 0,
        durasiDetik: _toInt(l['durasi_detik']) ?? 0,
        gambarIds:
            foto.map((g) => _toInt(g['id'])).whereType<int>().toList(),
        gambarUrls: foto
            .map((g) => (g['url'] ?? '').toString())
            .where((u) => u.isNotEmpty)
            .toList(),
      );
    }).toList();

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
      kategoriNama: kategori.map((k) => k['nama'].toString()).toList(),
      ingredientsRaw: bahanDetail.map((b) => b.teks).toList(),
      ingredientsKeywords: keywords,
      stepsList: langkah.map((l) => (l['instruksi'] ?? '').toString()).toList(),
      bahanDetail: bahanDetail,
      langkahDetail: langkahDetail,
      calories: null,
      proteins: null,
      fat: null,
      carbohydrate: null,
      hasNutrition: false,
      nutritionSource: 'missing',
      loves: _toInt(j['jumlah_favorit']) ?? 0,
      origin: mine ? 'custom' : 'system',
      isPublished: (j['status'] as String? ?? 'terbit') == 'terbit',
      ownerId: mine ? j['pemilik_id']?.toString() : null,
      description: (j['deskripsi'] ?? '').toString(),
      durationText:
          j['waktu_masak'] == null ? null : '${j['waktu_masak']} mnt',
      servings: j['porsi'] == null ? null : '${j['porsi']} Porsi',
      // harga_resep dikirim Laravel sebagai string ("10000.00").
      estCostManual: _toInt(j['harga_resep']),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      photoUrl: ((j['gambar_utama'] as Map?)?['url'])?.toString(),
      ratingRata: double.tryParse(
          (j['rating_rata'] ?? '').toString()),
      jumlahPenilai: _toInt(j['jumlah_penilai']) ?? 0,
      ownerName: ((j['pemilik'] as Map?)?['nama_tampil'])?.toString(),
      ownerPhotoUrl:
          (((j['pemilik'] as Map?)?['foto'] as Map?)?['url'])?.toString(),
    );
  }

  /// Terima angka atau string dari API (decimal Laravel = string).
  int? _toInt(dynamic v) =>
      v == null ? null : num.tryParse(v.toString())?.toInt();

  /// "500.00" -> "500", "0.50" -> "0.5"
  String _angka(dynamic v) {
    if (v == null) return '';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }
}
