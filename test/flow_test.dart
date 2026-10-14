import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/main.dart';

void main() {
  testWidgets('alur splash login home', (t) async {
    await t.pumpWidget(const MasakYukApp());
    await t.pump(const Duration(milliseconds: 2500));
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    await t.tap(find.text('Masuk dengan Google'));
    await t.pumpAndSettle();
    expect(find.text('Cari Resep'), findsOneWidget);
  });
}
