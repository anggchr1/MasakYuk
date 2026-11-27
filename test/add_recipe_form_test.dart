import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/recipe_repository.dart';
import 'package:masakyuk/features/recipe_form/add_recipe_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('form resep baru tampil dengan gambar bawaan, satuan, dan durasi',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final repo = RecipeRepository();

    await t.pumpWidget(
        MaterialApp(home: AddRecipeScreen(repo: repo)));
    await t.pumpAndSettle();

    expect(find.text('Resep Baru'), findsOneWidget);
    // Tanpa unggahan: gambar bawaan resep, bukan foto kategori.
    expect(find.text('Gambar Bawaan Resep'), findsOneWidget);

    // Bahan punya pilihan satuan & langkah punya isian durasi (di bawah).
    await t.dragUntilVisible(find.text('Waktu:'), find.byType(ListView),
        const Offset(0, -300));
    expect(find.byType(DropdownButton<String>), findsWidgets);
  });
}