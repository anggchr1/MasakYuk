import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/api_recipe_source.dart';
import 'package:masakyuk/data/recipe_photo.dart';

void main() {
  test('resep tanpa foto memakai gambar bawaan seperti web', () {
    final r = ApiRecipeSource().toRecipe({'id': 1, 'judul': 'Nasi Goreng'});
    expect(photoFor(r), fotoResepBawaan);
  });

  test('foto unggahan tetap dipakai', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 1,
      'judul': 'Nasi Goreng',
      'gambar_utama': {'url': 'https://contoh.test/foto.jpg'},
    });
    expect(photoFor(r), 'https://contoh.test/foto.jpg');
  });
}
