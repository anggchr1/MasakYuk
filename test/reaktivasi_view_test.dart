import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/recipe_repository.dart';
import 'package:masakyuk/features/auth/auth_provider.dart';
import 'package:masakyuk/features/auth/reaktivasi_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('layar reaktivasi mengisi email akun yang dinonaktifkan',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthProvider(RecipeRepository())
      ..perluReaktivasi = true
      ..surelTertahan = 'aku@example.com';

    await t.pumpWidget(
      MaterialApp(home: ReaktivasiScreen(auth: auth)),
    );

    expect(find.text('Aktifkan Kembali Akun'), findsOneWidget);
    expect(find.text('aku@example.com'), findsOneWidget);
    expect(find.text('Kirim Kode OTP'), findsOneWidget);
  });

  testWidgets('email kosong ditolak sebelum memanggil server', (t) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthProvider(RecipeRepository())..perluReaktivasi = true;

    await t.pumpWidget(
      MaterialApp(home: ReaktivasiScreen(auth: auth)),
    );

    await t.tap(find.text('Kirim Kode OTP'));
    await t.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(auth.error, isNull);
  });
}