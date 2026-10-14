import 'package:flutter/foundation.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';

/// State Home v2: search nama + checklist bahan + chip + budget.
/// NANTI: tambah debounce sebelum query Firestore (hemat reads).
class HomeProvider extends ChangeNotifier {
  final RecipeRepository repo;
  HomeProvider(this.repo);

  String chip = 'Semua';
  String query = '';
  String titleQuery = '';
  final Set<String> picked = {};
  bool showAll = false;

  static const chips = [
    'Semua',
    'pedas',
    'cepat',
    'sarapan',
    'unggas',
    'daging',
    'seafood',
    'nabati',
    'telur'
  ];

  static const bahanChips = [
    'telur',
    'ayam',
    'cabai',
    'bawang',
    'tahu',
    'tempe',
    'tomat',
    'santan',
  ];

  void setChip(String c) {
    chip = c;
    showAll = false;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    showAll = false;
    notifyListeners();
  }

  void setTitle(String q) {
    titleQuery = q;
    showAll = false;
    notifyListeners();
  }

  void togglePick(String b) {
    if (!picked.remove(b)) picked.add(b);
    showAll = false;
    notifyListeners();
  }

  void revealAll() {
    showAll = true;
    notifyListeners();
  }

  /// Gabungan kata ketik + chip terpilih.
  Set<String> get inputs => {
        ...query
            .toLowerCase()
            .split(RegExp(r'[^a-z]+'))
            .where((w) => w.length >= 3),
        ...picked,
      };

  bool get searching =>
      inputs.isNotEmpty ||
      titleQuery.trim().isNotEmpty ||
      chip != 'Semua' ||
      showAll;

  ({List<Recipe> top3, List<Recipe> rest}) get results {
    if (titleQuery.trim().isNotEmpty) {
      final all = repo.searchTitle(titleQuery.trim());
      return (top3: all.take(3).toList(), rest: all.skip(3).take(17).toList());
    }
    if (chip == 'Semua') return repo.search(inputs);
    final t = repo.byTag(chip);
    return (top3: t.take(3).toList(), rest: t.skip(3).take(17).toList());
  }
}
