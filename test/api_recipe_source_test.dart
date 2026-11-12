import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/api_recipe_source.dart';
import 'package:masakyuk/data/recipe_photo.dart';

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

  test('foto unggahan dipakai sebagai photoUrl', () {
    final api = ApiRecipeSource();
    final r = api.toRecipe({
      'id': 5,
      'judul': 'Nasi Foto',
      'gambar_utama': {
        'url': 'https://res.cloudinary.com/demo/image/upload/nasi.jpg',
      },
    });

    expect(r.photoUrl, 'https://res.cloudinary.com/demo/image/upload/nasi.jpg');
    expect(photoFor(r), r.photoUrl);
    expect(api.toRecipe({'id': 6, 'judul': 'Tanpa Foto'}).photoUrl, isNull);
  });

  test('harga_resep string dari API tetap terbaca sebagai angka', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 7,
      'judul': 'Nasgor',
      'status': 'draf',
      'porsi': 4,
      'waktu_masak': 35,
      'harga_resep': '10000.00',
    }, mine: true);

    expect(r.estCostManual, 10000);
    expect(r.isPublished, isFalse);
  });

  test('rating dari API berupa string tetap terbaca', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 12,
      'judul': 'Nasgor',
      'rating_rata': '5.0000', // avg() Laravel dikirim sebagai string
      'jumlah_penilai': 1,
    });

    expect(r.ratingRata, 5.0);
    expect(r.jumlahPenilai, 1);
    expect(r.displayRating, '5.0');
  });

  test('jumlah_favorit dari API menjadi loves (dihitung di Profil)', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 26,
      'judul': 'Sate Maranggi',
      'jumlah_favorit': 1,
    });

    expect(r.loves, 1);
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
