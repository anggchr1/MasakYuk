import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/models/know.dart';

void main() {
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
}
