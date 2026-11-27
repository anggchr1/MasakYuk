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

  testWidgets('tidak ada kategori terpilih & batal tag baru tidak error',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final repo = RecipeRepository();

    await t.pumpWidget(MaterialApp(home: AddRecipeScreen(repo: repo)));
    await t.pumpAndSettle();

    // Awalan: semua chip kategori belum terpilih.
    final chip = t.widget<FilterChip>(find.widgetWithText(FilterChip, 'Tradisional'));
    expect(chip.selected, isFalse);

    await t.dragUntilVisible(find.text('Tag Baru'), find.byType(ListView),
        const Offset(0, -300));
    await t.tap(find.text('Tag Baru'));
    await t.pumpAndSettle();
    await t.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Batal')));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(find.text('Tag Kategori Baru'), findsNothing);
  });
}