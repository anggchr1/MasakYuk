import 'package:flutter/foundation.dart';
import '../../data/recipe_repository.dart';

/// State Home v2: chip bahan (toggle manual) + query + chip kategori.
/// TIDAK auto-search: hasil dibuka lewat layar Hasil (pill / submit / chip).
class HomeProvider extends ChangeNotifier {
  final RecipeRepository repo;
  HomeProvider(this.repo);

  String chip = 'Semua';
  String query = '';
  String titleQuery = '';
  final Set<String> picked = {};
  bool applied = false;

  static const chips = [
    'Semua',
    'Sarapan',
    'Cepat & Mudah',
    'Pedas',
    'Nusantara',
    'Ayam & Daging',
    'Seafood',
    'Sayuran',
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
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void setTitle(String q) {
    titleQuery = q;
    notifyListeners();
  }

  void togglePick(String b) {
    if (!picked.remove(b)) picked.add(b);
    notifyListeners();
  }

  void clearPicks() {
    picked.clear();
    query = '';
    applied = false;
    notifyListeners();
  }

  /// Gabungan kata ketik + chip terpilih (dipakai saat pill ditekan).
  Set<String> get inputs => {
        ...query
            .toLowerCase()
            .split(RegExp(r'[^a-z]+'))
            .where((w) => w.length >= 3),
        ...picked,
      };
}
