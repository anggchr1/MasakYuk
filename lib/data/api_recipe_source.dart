import '../core/api/api_client.dart';
import '../models/recipe.dart';

/// Sumber resep dari REST API backend MasakYuk.
/// GET /api/v1/resep        -> daftar (id, judul, ...)
/// GET /api/v1/resep/{id}   -> detail (bahan_resep, langkah_resep, kategori)
class ApiRecipeSource {
  final ApiClient api;
  ApiRecipeSource([ApiClient? api]) : api = api ?? ApiClient();

  Future<List<Recipe>> fetchAll() async {
    final index = await api.get('/api/v1/resep');
    final items =
        ((index['data'] as List?) ?? const []).cast<Map<String, dynamic>>();

    // Detail dibutuhkan untuk bahan & langkah.
    final details = await Future.wait(
      items.map((e) => api.get('/api/v1/resep/${e['id']}')),
    );
    return details
        .whereType<Map<String, dynamic>>()
        .map(toRecipe)
        .toList();
  }

  Recipe toRecipe(Map<String, dynamic> j) {
    final bahan =
        ((j['bahan_resep'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final langkah = (((j['langkah_resep'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
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
      origin: 'system',
      isPublished: true,
      description: (j['deskripsi'] ?? '').toString(),
      durationText:
          j['waktu_masak'] == null ? null : '${j['waktu_masak']} mnt',
      servings: j['porsi'] == null ? null : '${j['porsi']} Porsi',
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
