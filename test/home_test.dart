import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/recipe_repository.dart';
import 'package:masakyuk/features/home/home_view.dart';

void main() {
  testWidgets('home builds tanpa exception', (t) async {
    final repo = RecipeRepository();
    await repo.load();
    await t.pumpWidget(
        MaterialApp(home: Scaffold(body: HomeScreen(repo: repo))));
    await t.pumpAndSettle();
    expect(find.text('Cari Resep'), findsWidgets);
  });
}
