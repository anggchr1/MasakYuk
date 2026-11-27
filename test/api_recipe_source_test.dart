import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:masakyuk/core/api/api_client.dart';
import 'package:masakyuk/data/api_recipe_source.dart';
import 'package:masakyuk/data/recipe_photo.dart';
import 'package:masakyuk/models/recipe.dart';

void main() {
  test('fetchAll mengirim page & kategori ke API', () async {
    late Uri terakhir;
    final api = ApiClient(
      baseUrl: 'https://contoh.test',
      client: MockClient((req) async {
        terakhir = req.url;
        return http.Response('{"data":[]}', 200);
      }),
    );
    final sumber = ApiRecipeSource(api);

    await sumber.fetchAll(page: 3, kategori: 'ayam');
    expect(terakhir.queryParameters, {'page': '3', 'kategori': 'ayam'});

    await sumber.fetchAll();
    expect(terakhir.queryParameters, isEmpty);
  });

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

  test('pemilik resep dipetakan ke nama & foto pembuat', () {
    final api = ApiRecipeSource();
    final r = api.toRecipe({
      'id': 4,
      'judul': 'Rendang',
      'pemilik': {
        'id': 3,
        'nama_tampil': 'Chef Angga',
        'foto': {'url': 'https://contoh.test/avatar.jpg'},
      },
    });

    expect(r.ownerName, 'Chef Angga');
    expect(r.ownerPhotoUrl, 'https://contoh.test/avatar.jpg');
    expect(api.toRecipe({'id': 5, 'judul': 'Tanpa Pemilik'}).ownerName, isNull);
  });

  test('jumlah_favorit dari API menjadi loves (dihitung di Profil)', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 26,
      'judul': 'Sate Maranggi',
      'jumlah_favorit': 1,
    });

    expect(r.loves, 1);
  });

  test('toRecipe membaca grup bahan, durasi, dan foto langkah', () {
    final r = ApiRecipeSource().toRecipe({
      'id': 3,
      'judul': 'Sop Ayam',
      'bahan_resep': [
        {
          'jumlah': '2',
          'satuan': 'sdm',
          'grup': 'Bumbu',
          'bahan': {'nama': 'kecap'},
        },
      ],
      'langkah_resep': [
        {
          'nomor_langkah': 1,
          'instruksi': 'Rebus',
          'durasi_menit': 5,
          'durasi_detik': 30,
          'gambar': {'id': 11, 'url': 'https://contoh.test/1.jpg'},
          'gambar2': {'id': 12, 'url': 'https://contoh.test/2.jpg'},
        },
      ],
    });

    expect(r.bahanDetail.single.grup, 'Bumbu');
    expect(r.ingredientsRaw.single, '2 sdm kecap');
    expect(r.langkahDetail.single.totalDetik, 330);
    expect(r.langkahDetail.single.durasiLabel, '5 mnt 30 dtk');
    expect(r.langkahDetail.single.gambarIds, [11, 12]);
  });

  test('create mengirim takaran, grup, durasi, foto, dan tag baru', () async {
    late Map<String, dynamic> body;
    final api = ApiClient(
      baseUrl: 'https://contoh.test',
      client: MockClient((req) async {
        if (req.url.path.endsWith('/kategori-resep')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'nama': 'Pedas', 'slug': 'pedas'},
            ]),
            200,
          );
        }
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 9,
            'judul': 'Sambal',
            'bahan_resep': [],
            'langkah_resep': [],
            'kategori_resep': [],
          }),
          201,
        );
      }),
    );

    await ApiRecipeSource(api).create(
      judul: 'Sambal',
      kategoriNama: ['Pedas', 'Masakan Sunda'],
      bahan: const [
        RecipeIngredient(
          nama: 'bawang',
          jumlah: '1/2',
          satuan: 'sdt',
          grup: 'Bumbu',
        ),
      ],
      langkah: const [
        RecipeStep(
          instruksi: 'Haluskan',
          durasiMenit: 2,
          durasiDetik: 30,
          gambarIds: [7],
        ),
      ],
    );

    expect(body['kategori_ids'], [1]);
    expect(body['kategori_namas'], ['Masakan Sunda']);
    expect((body['bahan'] as List).first, {
      'nama': 'bawang',
      'jumlah': '1/2',
      'satuan': 'sdt',
      'grup': 'Bumbu',
    });
    final langkah = (body['langkah'] as List).first as Map;
    expect(langkah['durasi_menit'], 2);
    expect(langkah['durasi_detik'], 30);
    expect(langkah['gambar_id_1'], 7);
  });
}
