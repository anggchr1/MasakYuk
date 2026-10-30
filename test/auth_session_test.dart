import 'package:flutter_test/flutter_test.dart';
import 'package:masakyuk/data/recipe_repository.dart';
import 'package:masakyuk/features/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sesi tersimpan dipakai bila belum kedaluwarsa', () async {
    SharedPreferences.setMockInitialValues({
      'sesi.token': 'abc',
      'sesi.kedaluwarsa': DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'sesi.nama': 'Rani',
      'sesi.surel': 'rani@example.com',
    });
    final repo = RecipeRepository();
    final auth = AuthProvider(repo);

    await auth.muatSesi();

    expect(auth.loggedIn, isTrue);
    expect(auth.isGuest, isFalse);
    expect(repo.userName, 'Rani');
    expect(repo.api.token, 'abc');
  });

  test('sesi kedaluwarsa wajib login ulang', () async {
    SharedPreferences.setMockInitialValues({
      'sesi.token': 'abc',
      'sesi.kedaluwarsa': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });
    final repo = RecipeRepository();
    final auth = AuthProvider(repo);

    await auth.muatSesi();

    expect(auth.loggedIn, isFalse);
    expect(repo.api.token, isNull);
  });
}
