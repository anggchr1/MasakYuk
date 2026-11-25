import '../models/recipe.dart';

/// Gambar bawaan untuk resep tanpa foto, sama seperti web
/// (`assets/images/resep/default-resep.png`).
const String fotoResepBawaan = 'assets/images/default_resep.png';

/// Foto unggahan sendiri; kalau tidak ada, pakai gambar bawaan.
String photoFor(Recipe r) {
  final url = r.photoUrl;
  if (url != null && url.isNotEmpty) return url;
  return fotoResepBawaan;
}
