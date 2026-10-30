import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/api_recipe_source.dart';

void main() {
  test('toRecipe memetakan detail JSON API ke model Recipe', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 2,
      'judul': 'Ayam Goreng',
      'deskripsi': 'Ayam goreng bumbu kuning.',
      'porsi': 4,
      'waktu_masak': 30,
      'created_at': '2026-10-27T04:45:51.000000Z',
      'kategori_resep': [
        {'id': 1, 'nama': 'Lauk', 'slug': 'lauk'},
      ],
      'bahan_resep': [
        {
          'jumlah': '500.00',
          'satuan': 'gram',
          'bahan': {'nama': 'ayam fillet'},
        },
        {
          'jumlah': '3.00',
          'satuan': 'siung',
          'bahan': {'nama': 'bawang putih'},
        },
      ],
      'langkah_resep': [
        {'nomor_langkah': 2, 'instruksi': 'Goreng.'},
        {'nomor_langkah': 1, 'instruksi': 'Haluskan.'},
      ],
    });

    expect(r.docId, '2');
    expect(r.title, 'Ayam Goreng');
    expect(r.category, 'Lauk');
    expect(r.tags, ['lauk']);
    expect(r.servings, '4 Porsi');
    expect(r.durationText, '30 mnt');
    expect(r.ingredientsRaw.first, '500 gram ayam fillet');
    expect(r.stepsList, ['Haluskan.', 'Goreng.']); // urut nomor_langkah
    expect(r.ingredientsKeywords,
        containsAll(['ayam', 'fillet', 'bawang', 'putih']));
  });

  test('resep milik sendiri: status draf -> belum terbit', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 9,
      'judul': 'Draf Rahasia',
      'status': 'draf',
      'pemilik_id': 3,
    }, mine: true);

    expect(r.isPublished, isFalse);
    expect(r.origin, 'custom');
    expect(r.ownerId, '3');
  });

  test('bahanPayload memecah jumlah & satuan', () {
    final api = ApiRecipeSource();
    expect(api.bahanPayload('2 siung bawang putih'),
        {'nama': 'bawang putih', 'jumlah': 2, 'satuan': 'siung'});
    expect(api.bahanPayload('500 gram ayam fillet'),
        {'nama': 'ayam fillet', 'jumlah': 500, 'satuan': 'gram'});
    expect(api.bahanPayload('garam secukupnya'),
        {'nama': 'garam secukupnya'});
    expect(api.bahanPayload('1/2 sdt merica'),
        {'nama': 'merica', 'jumlah': 0.5, 'satuan': 'sdt'});
  });
}
