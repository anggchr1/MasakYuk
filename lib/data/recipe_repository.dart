import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';

/// Sumber data sementara: assets/sample_recipes.json (24 resep).
/// NANTI (M2): ganti _loadLocal dengan query Firestore:
///   recipes_master limit(20) + recipes where isPublished==true + milik uid.
/// Interface search/top3/rest TIDAK berubah.
class RecipeRepository extends ChangeNotifier {
  final List<Recipe> _system = [];
  final List<Recipe> _custom = [];
  final Set<String> _favorites = {};
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

  /// Pool pencarian = master + custom yang publish + custom milik sendiri.
  List<Recipe> get _pool => [
        ..._system,
        ..._custom.where((r) => r.isPublished || r.ownerId == 'local'),
      ];

  Future<void> load() async {
    if (loaded) return;
    final raw = await rootBundle.loadString('assets/sample_recipes.json');
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    _system.addAll(list.map(Recipe.fromJson));
    loaded = true;
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

  void toggleFavorite(String docId) {
    if (!_favorites.remove(docId)) _favorites.add(docId);
    notifyListeners();
  }

  void addCustom({
    required String title,
    required String category,
    required List<String> ingredients,
    required List<String> steps,
    required bool publish,
    String description = '',
    String? durationText,
    String? difficulty,
    String? servings,
  }) {
    final kws = ingredients
        .join(' ')
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length >= 3)
        .toSet()
        .take(20)
        .toList();
    _custom.add(Recipe(
      docId: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      tags: [category.toLowerCase()],
      ingredientsRaw: ingredients,
      ingredientsKeywords: kws,
      stepsList: steps,
      calories: null,
      proteins: null,
      fat: null,
      carbohydrate: null,
      hasNutrition: false, // NANTI: estimasi Gemini saat dibuka (M3)
      nutritionSource: 'missing',
      loves: 0,
      origin: 'custom',
      isPublished: publish,
      ownerId: 'local',
      description: description,
      durationText: durationText,
      difficulty: difficulty,
      servings: servings,
    ));
    notifyListeners();
  }

  /// Kelola resep sendiri (Profil → Koleksi Terbitan).
  void deleteCustom(String docId) {
    _custom.removeWhere((r) => r.docId == docId);
    _favorites.remove(docId);
    notifyListeners();
  }

  void togglePublish(String docId) {
    final i = _custom.indexWhere((r) => r.docId == docId);
    if (i < 0) return;
    final r = _custom[i];
    _custom[i] = Recipe(
      docId: r.docId,
      title: r.title,
      category: r.category,
      tags: r.tags,
      ingredientsRaw: r.ingredientsRaw,
      ingredientsKeywords: r.ingredientsKeywords,
      stepsList: r.stepsList,
      calories: r.calories,
      proteins: r.proteins,
      fat: r.fat,
      carbohydrate: r.carbohydrate,
      hasNutrition: r.hasNutrition,
      nutritionSource: r.nutritionSource,
      loves: r.loves,
      origin: r.origin,
      isPublished: !r.isPublished,
      ownerId: r.ownerId,
      description: r.description,
      durationText: r.durationText,
      difficulty: r.difficulty,
      servings: r.servings,
    );
    notifyListeners();
  }

  void logout() {
    _favorites.clear();
    notifyListeners();
  }
}
