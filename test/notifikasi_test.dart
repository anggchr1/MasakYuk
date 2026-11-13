import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/models/social.dart';

void main() {
  test('notifikasi komentar dari API dipetakan ke NotifItem', () {
    final n = NotifItem.dariServer({
      'id': 7,
      'jenis': 'komentar',
      'judul': 'Komentar Baru pada Resep Anda',
      'isi': '"Bu**" baru memberikan komentar pada resep "Soto Uji".',
      'tipe_terkait': 'resep',
      'id_terkait': 12,
      'dibaca': false,
      'created_at': '2026-11-13T10:00:00.000000Z',
    });

    expect(n.id, '7');
    expect(n.kind, 'komentar');
    expect(n.title, contains('Komentar'));
    expect(n.recipeId, '12');
    expect(n.read, isFalse);
    expect(n.at.isAfter(DateTime(2020)), isTrue);
  });

  test('notifikasi tanpa resep terkait dan sudah dibaca tetap aman', () {
    final n = NotifItem.dariServer({'id': 1, 'judul': 'Halo', 'dibaca': 1});

    expect(n.recipeId, isNull);
    expect(n.read, isTrue);
    expect(n.desc, isEmpty);
  });
}
