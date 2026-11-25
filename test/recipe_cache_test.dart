import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/api_recipe_source.dart';
import 'package:masakyuk/models/recipe.dart';

void main() {
  test('resep bisa disimpan lalu dibaca ulang dari cache offline', () {
    final asli = ApiRecipeSource().toRecipe({
      'id': 7,
      'judul': 'Soto Ayam',
      'status': 'draf',
      'loves': 5,
      'jumlah_penilai': 3,
      'rating_rata': '4.5',
      'deskripsi': 'Enak',
      'waktu_masak': 30,
      'porsi': 2,
      'harga_resep': '15000.00',
      'gambar_utama': {'url': 'https://contoh.test/soto.jpg'},
      'bahan_resep': [
        {
          'jumlah': '2',
          'satuan': 'siung',
          'bahan': {'nama': 'bawang'},
        },
      ],
      'langkah_resep': [
        {'nomor_langkah': 1, 'instruksi': 'Rebus'},
      ],
      'kategori_resep': [
        {'nama': 'Ayam & Daging', 'slug': 'ayam'},
      ],
    });

    final salinan = Recipe.fromJson(asli.toJson());
    expect(salinan.docId, asli.docId);
    expect(salinan.title, asli.title);
    expect(salinan.category, asli.category);
    expect(salinan.tags, asli.tags);
    expect(salinan.ingredientsRaw, asli.ingredientsRaw);
    expect(salinan.stepsList, asli.stepsList);
    expect(salinan.loves, asli.loves);
    expect(salinan.jumlahPenilai, asli.jumlahPenilai);
    expect(salinan.ratingRata, asli.ratingRata);
    expect(salinan.isPublished, asli.isPublished);
    expect(salinan.photoUrl, asli.photoUrl);
    expect(salinan.durationText, asli.durationText);
    expect(salinan.servings, asli.servings);
    expect(salinan.estCostManual, asli.estCostManual);
  });
}
