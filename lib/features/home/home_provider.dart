import 'package:flutter/foundation.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';

/// State layar Home: chip filter + query + buka "lihat lainnya".
/// NANTI: tambah debounce sebelum query Firestore (hemat reads).
class HomeProvider extends ChangeNotifier {
  final RecipeRepository repo;
  HomeProvider(this.repo);

  String chip = 'Semua';
  String query = '';
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

  void revealAll() {
    showAll = true;
    notifyListeners();
  }

  Set<String> get inputs => query
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.length >= 3)
      .toSet();

  ({List<Recipe> top3, List<Recipe> rest}) get results =>
      chip == 'Semua'
          ? repo.search(inputs)
          : (
              top3: repo.byTag(chip).take(3).toList(),
              rest: repo.byTag(chip).skip(3).take(17).toList(),
            );
}
