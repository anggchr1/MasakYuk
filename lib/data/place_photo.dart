import '../models/know.dart';
import 'food_photos.dart';

/// Foto asli dari OSM bila ada; selain itu ilustrasi sesuai kategori.
/// Ilustrasi ditandai di UI supaya tidak dikira foto tempat sebenarnya.
String placePhoto(PlaceInfo p) {
  if (p.foto.isNotEmpty) return p.foto;
  const kunci = {
    'Tempat Makan': 'nasi',
    'Kafe': 'dessert',
    'Pasar': 'seafood',
  };
  final pool = FoodPhotos.pool[kunci[p.jenis]] ?? FoodPhotos.fallback;
  return pool[p.id.hashCode.abs() % pool.length];
}

/// True = gambar ilustrasi, bukan foto asli tempat.
bool placePhotoIlustrasi(PlaceInfo p) => p.foto.isEmpty;
