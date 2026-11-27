/// Satu bahan terstruktur: takaran + satuan + grup (sinkron dengan form web).
class RecipeIngredient {
  final String nama;
  final String jumlah;
  final String satuan;
  final String grup;

  const RecipeIngredient({
    required this.nama,
    this.jumlah = '',
    this.satuan = '',
    this.grup = '',
  });

  String get teks =>
      [jumlah, satuan, nama].where((s) => s.isNotEmpty).join(' ');

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) =>
      RecipeIngredient(
        nama: (j['nama'] ?? '').toString(),
        jumlah: (j['jumlah'] ?? '').toString(),
        satuan: (j['satuan'] ?? '').toString(),
        grup: (j['grup'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'jumlah': jumlah,
        'satuan': satuan,
        'grup': grup,
      };
}

/// Satu langkah memasak: instruksi + durasi + foto proses (maks 3).
class RecipeStep {
  final String instruksi;
  final int durasiMenit;
  final int durasiDetik;
  final List<int> gambarIds;
  final List<String> gambarUrls;

  const RecipeStep({
    required this.instruksi,
    this.durasiMenit = 0,
    this.durasiDetik = 0,
    this.gambarIds = const [],
    this.gambarUrls = const [],
  });

  int get totalDetik => durasiMenit * 60 + durasiDetik;

  String get durasiLabel {
    if (totalDetik == 0) return '';
    if (durasiMenit == 0) return '$durasiDetik dtk';
    return durasiDetik == 0
        ? '$durasiMenit mnt'
        : '$durasiMenit mnt $durasiDetik dtk';
  }

  factory RecipeStep.fromJson(Map<String, dynamic> j) => RecipeStep(
        instruksi: (j['instruksi'] ?? '').toString(),
        durasiMenit: (j['durasi_menit'] as num?)?.toInt() ?? 0,
        durasiDetik: (j['durasi_detik'] as num?)?.toInt() ?? 0,
        gambarIds: (j['gambar_ids'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        gambarUrls: (j['gambar_urls'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'instruksi': instruksi,
        'durasi_menit': durasiMenit,
        'durasi_detik': durasiDetik,
        'gambar_ids': gambarIds,
        'gambar_urls': gambarUrls,
      };
}

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
  final List<String> kategoriNama; // semua kategori (bisa lebih dari satu)
  final List<RecipeIngredient> bahanDetail; // takaran/satuan/grup
  final List<RecipeStep> langkahDetail; // durasi + foto proses
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
  final String? servings; // cth "3-4 Porsi"
  final int? estCostManual; // input user (Rp total), null = hitung tabel
  final DateTime? createdAt; // resep custom (untuk purge draf lama)
  final String? photoUrl; // foto unggahan user (Cloudinary); null = foto kategori
  final double? ratingRata; // rata-rata skor dari server
  final int jumlahPenilai;

  const Recipe({
    required this.docId,
    required this.title,
    required this.category,
    required this.tags,
    required this.ingredientsRaw,
    required this.ingredientsKeywords,
    required this.stepsList,
    this.kategoriNama = const [],
    this.bahanDetail = const [],
    this.langkahDetail = const [],
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
    this.servings,
    this.estCostManual,
    this.createdAt,
    this.photoUrl,
    this.ratingRata,
    this.jumlahPenilai = 0,
  });

  static List<String> _strList(dynamic v) =>
      (v as List? ?? []).map((e) => e.toString()).toList();

  static double? _num(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  factory Recipe.fromJson(Map<String, dynamic> j) {
    final nut = (j['nutrition'] as Map?) ?? {};
    final hasNut = j['has_nutrition'] as bool? ?? _num(nut['calories']) != null;
    final bahanJson =
        (j['bahan_detail'] as List?)?.cast<Map<String, dynamic>>();
    final langkahJson =
        (j['langkah_detail'] as List?)?.cast<Map<String, dynamic>>();
    return Recipe(
      docId: j['doc_id'] as String? ?? j['docId'] as String? ?? '',
      title: j['title'] as String? ?? '-',
      category: j['category'] as String? ?? 'Lainnya',
      tags: _strList(j['tags']),
      ingredientsRaw: _strList(j['ingredients_raw']),
      ingredientsKeywords: _strList(j['ingredients_keywords']),
      stepsList: _strList(j['steps_list']),
      kategoriNama: _strList(j['kategori_nama']),
      // Cache lama belum punya detail: pecah dari teks utuh agar tetap bisa diubah.
      bahanDetail: bahanJson != null
          ? bahanJson.map(RecipeIngredient.fromJson).toList()
          : _strList(j['ingredients_raw'])
              .map((t) => RecipeIngredient(nama: t))
              .toList(),
      langkahDetail:
          langkahJson?.map(RecipeStep.fromJson).toList() ?? const [],
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
      servings: j['servings'] as String?,
      estCostManual: (j['estCostManual'] as num?)?.toInt(),
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'] as String),
      photoUrl: ((j['gambar_utama'] as Map?)?['url'])?.toString(),
      ratingRata: double.tryParse((j['rating_rata'] ?? '').toString()),
      jumlahPenilai: (j['jumlah_penilai'] as num?)?.toInt() ?? 0,
    );
  }

  /// Kebalikan [Recipe.fromJson] — untuk cache offline.
  Map<String, dynamic> toJson() => {
        'doc_id': docId,
        'title': title,
        'category': category,
        'tags': tags,
        'kategori_nama': kategoriNama,
        'ingredients_raw': ingredientsRaw,
        'ingredients_keywords': ingredientsKeywords,
        'steps_list': stepsList,
        'bahan_detail': bahanDetail.map((b) => b.toJson()).toList(),
        'langkah_detail': langkahDetail.map((l) => l.toJson()).toList(),
        'nutrition': {
          'calories': calories,
          'proteins': proteins,
          'fat': fat,
          'carbohydrate': carbohydrate,
        },
        'has_nutrition': hasNutrition,
        'nutrition_source': nutritionSource,
        'loves': loves,
        'origin': origin,
        'isPublished': isPublished,
        'ownerId': ownerId,
        'description': description,
        'durationText': durationText,
        'servings': servings,
        'estCostManual': estCostManual,
        'createdAt': createdAt?.toIso8601String(),
        'gambar_utama': photoUrl == null ? null : {'url': photoUrl},
        'rating_rata': ratingRata,
        'jumlah_penilai': jumlahPenilai,
      };

  /// Badge durasi di kartu: master tidak punya data, jadi pakai
  /// heuristik (±5 mnt/langkah). Custom pakai input user.
  String get displayDuration =>
      durationText ?? '±${(stepsList.length * 5).clamp(10, 120)} mnt';

  /// Badge rating di kartu: rata-rata skor, "-" bila belum ada penilai.
  String get displayRating {
    if (jumlahPenilai == 0 || ratingRata == null) return '-';
    return ratingRata!.toStringAsFixed(1);
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
