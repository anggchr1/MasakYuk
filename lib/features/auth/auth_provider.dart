import 'package:flutter/foundation.dart';
import '../../data/recipe_repository.dart';

/// State login. v1: mock. NANTI M2: google_sign_in + FirebaseAuth,
/// userName/email diisi dari FirebaseUser.
class AuthProvider extends ChangeNotifier {
  final RecipeRepository repo;
  AuthProvider(this.repo);

  bool loggedIn = false;

  void login() {
    loggedIn = true;
    notifyListeners();
  }

  /// Mode tamu: masuk tanpa akun, data tidak tersinkron.
  void loginAsGuest() {
    repo.userName = 'Tamu';
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    repo.logout();
    loggedIn = false;
    notifyListeners();
  }
}
