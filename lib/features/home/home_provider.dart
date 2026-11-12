import 'package:flutter/foundation.dart';
import '../../data/recipe_repository.dart';

/// State Home v2: bahan yang diketik user + chip kategori.
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

  void tambah(String teks) {
    picked.addAll(_kataBahan(teks));
    notifyListeners();
  }

  /// "Telor" -> telur; kata < 3 huruf (di, ke) dibuang.
  static const _sinonim = {'telor': 'telur', 'cabe': 'cabai'};

  static Iterable<String> _kataBahan(String teks) => teks
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.length >= 3)
      .map((w) => _sinonim[w] ?? w);

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

  /// Bahan yang diketik user — dipakai saat tombol "Cari" ditekan.
  Set<String> get inputs => {...picked};
}
