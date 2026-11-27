import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/recipe_repository.dart';
import 'package:masakyuk/features/encyclopedia/encyclopedia_view.dart';
import 'package:masakyuk/models/know.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ensiklopedia tampil 24 entri dulu, sisanya lewat tombol',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final repo = RecipeRepository();
    await repo.load();
    final total = repo.ensiklopedia.length;

    await t.pumpWidget(MaterialApp(home: EncyclopediaScreen(repo: repo)));
    await t.pumpAndSettle();

    final awal = total < 24 ? total : 24;
    expect(find.textContaining('1–$awal dari $total bahan'), findsOneWidget);
    expect(find.text('Lihat bahan lagi'), findsOneWidget);
  });
  test('entri ensiklopedia dari API dipetakan ke IngredientInfo', () {
    final e = IngredientInfo.dariServer({
      'tipe': 'masakan',
      'nama': 'Rendang',
      'ringkasan': 'Rendang adalah hidangan dari Minangkabau.',
      'gambar_url': 'https://contoh.test/rendang.jpg',
      'sumber_url': 'https://id.wikipedia.org/wiki/Rendang',
    });

    expect(e.nama, 'Rendang');
    expect(e.kat, 'Masakan');
    expect(e.desc, 'Rendang adalah hidangan dari Minangkabau.');
    expect(e.gambar, 'https://contoh.test/rendang.jpg');
    expect(e.wiki, contains('Rendang'));
  });

  test('entri bahan tanpa gambar tetap valid', () {
    final e = IngredientInfo.dariServer({'nama': 'Kluwek'});

    expect(e.kat, 'Bahan');
    expect(e.gambar, isEmpty);
    expect(e.wiki, isEmpty);
  });

  test('respons API berupa array langsung terbaca', () {
    final list = ensiklopediaDariRespons([
      {'tipe': 'bahan', 'nama': 'Kunyit'},
      {'tipe': 'masakan', 'nama': 'Rendang'},
    ]);

    expect(list.length, 2);
    expect(list.last.kat, 'Masakan');
  });

  test('respons API berbentuk {data: [...]} tetap terbaca', () {
    final list = ensiklopediaDariRespons({
      'data': [
        {'nama': 'Kencur'},
      ],
    });

    expect(list.single.nama, 'Kencur');
  });

  test('respons kosong atau tak dikenal tidak melempar error', () {
    expect(ensiklopediaDariRespons(null), isEmpty);
    expect(ensiklopediaDariRespons(<String, dynamic>{}), isEmpty);
  });
}
