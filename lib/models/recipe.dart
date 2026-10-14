/// Model resep — field sama persis dengan recipes_master.json (DATABASE.md §1).
/// Dokumen custom (buatan user) memakai field yang sama + origin/isPublished.
class Recipe {
  final String docId;
  final String title;
  final String category;
  final List<String> tags;
  final List<String> ingredientsRaw; // utuh, untuk TAMPIL ("0.25 bawang merah")
  final List<String> ingredientsKeywords; // bersih, untuk CARI
  final List<String> stepsList;
  final double? calories;
  final double? proteins;
  final double? fat;
  final double? carbohydrate;
  final bool hasNutrition;
  final String nutritionSource; // dormant, tak tampil di UI (keputusan v2.1)
  final int loves;
  final String origin; // 'system' | 'custom'
  final bool isPublished;
  final String? ownerId;
  // Diisi user untuk resep custom; null di master (pakai estimasi di bawah).
  final String description;
  final String? durationText; // cth "35 mnt"
  final String? difficulty; // Mudah | Sedang | Sulit
  final String? servings; // cth "3-4 Porsi"
  final int? estCostManual; // input user (Rp total), null = hitung tabel
  final DateTime? createdAt; // resep custom (untuk purge draf lama)

  const Recipe({
    required this.docId,
    required this.title,
    required this.category,
    required this.tags,
    required this.ingredientsRaw,
    required this.ingredientsKeywords,
    required this.stepsList,
    required this.calories,
    required this.proteins,
    required this.fat,
    required this.carbohydrate,
    required this.hasNutrition,
    required this.nutritionSource,
    required this.loves,
    required this.origin,
    required this.isPublished,
    this.ownerId,
    this.description = '',
    this.durationText,
    this.difficulty,
    this.servings,
    this.estCostManual,
    this.createdAt,
  });

  static List<String> _strList(dynamic v) =>
      (v as List? ?? []).map((e) => e.toString()).toList();

  static double? _num(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  factory Recipe.fromJson(Map<String, dynamic> j) {
    final nut = (j['nutrition'] as Map?) ?? {};
    final hasNut = j['has_nutrition'] as bool? ?? _num(nut['calories']) != null;
    return Recipe(
      docId: j['doc_id'] as String? ?? j['docId'] as String? ?? '',
      title: j['title'] as String? ?? '-',
      category: j['category'] as String? ?? 'Lainnya',
      tags: _strList(j['tags']),
      ingredientsRaw: _strList(j['ingredients_raw']),
      ingredientsKeywords: _strList(j['ingredients_keywords']),
      stepsList: _strList(j['steps_list']),
      calories: _num(nut['calories']),
      proteins: _num(nut['proteins']),
      fat: _num(nut['fat']),
      carbohydrate: _num(nut['carbohydrate']),
      hasNutrition: hasNut,
      nutritionSource: j['nutrition_source'] as String? ?? 'missing',
      loves: (j['loves'] as num?)?.toInt() ?? 0,
      origin: j['origin'] as String? ?? 'system',
      isPublished: j['isPublished'] as bool? ?? true,
      ownerId: j['ownerId'] as String? ?? j['userId'] as String?,
      description: j['description'] as String? ?? '',
      durationText: j['durationText'] as String?,
      difficulty: j['difficulty'] as String?,
      servings: j['servings'] as String?,
      estCostManual: (j['estCostManual'] as num?)?.toInt(),
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'] as String),
    );
  }

  /// Badge durasi/kesulitan di kartu: master tidak punya data,
  /// jadi pakai heuristik (±5 mnt/langkah). Custom pakai input user.
  String get displayDuration =>
      durationText ?? '±${(stepsList.length * 5).clamp(10, 120)} mnt';
  String get displayDifficulty {
    if (difficulty != null) return difficulty!;
    final n = ingredientsRaw.length;
    if (n <= 6) return 'Mudah';
    if (n <= 10) return 'Sedang';
    return 'Sulit';
  }

  /// Status olah per bahan ala desain (Siap/Haluskan/Potong).
  static String prepStatus(String ingredient) {
    final t = ingredient.toLowerCase();
    if (t.contains('halus') ||
        t.contains('blender') ||
        t.contains('ulek')) {
      return 'Haluskan';
    }
    if (t.contains('potong') ||
        t.contains('iris') ||
        t.contains('cincang') ||
        t.contains('rajang')) {
      return 'Potong';
    }
    return 'Siap';
  }

  /// Skor kecocokan = jumlah keyword bahan user yang ada di resep.
  int matchScore(Set<String> input) {
    if (input.isEmpty) return 0;
    final repo = ingredientsKeywords.toSet();
    return input.where(repo.contains).length;
  }
}
