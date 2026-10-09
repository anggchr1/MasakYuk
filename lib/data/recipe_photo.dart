import '../models/recipe.dart';
import 'food_photos.dart';

/// Pilih foto Stitch berdasarkan bahan/kategori. Deterministik per resep.
/// NANTI: ganti dengan foto upload user (Storage) bila ada.
String photoFor(Recipe r) {
  final blob =
      '${r.title} ${r.ingredientsKeywords.join(' ')} ${r.category}'.toLowerCase();
  bool has(List<String> ks) => ks.any(blob.contains);
  if (has(['ayam', 'bebek', 'itik'])) return _pick(FoodPhotos.pool['ayam']!, r);
  if (has(['udang', 'cumi', 'ikan', 'lele', 'seafood', 'tuna', 'kepiting', 'kerang'])) {
    return _pick(FoodPhotos.pool['seafood']!, r);
  }
  if (has(['pecel'])) return _pick(FoodPhotos.pool['lele']!, r);
  if (has(['nasi', 'goreng'])) return _pick(FoodPhotos.pool['nasi']!, r);
  if (has(['soto', 'sop', 'sroto', 'bakso'])) return _pick(FoodPhotos.pool['sop']!, r);
  if (has(['mie', 'pasta', 'spaghetti', 'bihun'])) {
    return _pick(FoodPhotos.pool['pasta']!, r);
  }
  if (has(['kue', 'cokelat', 'muffin', 'roti', 'puding', 'cake', 'dessert'])) {
    return _pick(FoodPhotos.pool['dessert']!, r);
  }
  final fb = FoodPhotos.fallback;
  return fb[r.docId.hashCode.abs() % fb.length];
}

String _pick(List<String> pool, Recipe r) =>
    pool[r.docId.hashCode.abs() % pool.length];
