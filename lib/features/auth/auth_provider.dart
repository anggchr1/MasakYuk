import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/api/api_client.dart';
import '../../data/recipe_repository.dart';

/// Login Google di app = login Google di web:
/// id_token Google → POST /api/v1/auth/google/token → token Sanctum.
class AuthProvider extends ChangeNotifier {
  final RecipeRepository repo;
  final ApiClient api;
  AuthProvider(this.repo, {ApiClient? api}) : api = api ?? ApiClient();

  /// Harus sama dengan GOOGLE_CLIENT_ID di .env backend.
  /// Default = client ID milik project temanmu (sama dengan backend).
  /// Bisa diganti saat build:
  ///   flutter run --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '860000695247-luiafd1ap03006k4j8ulvs8mt5g8itgf.apps.googleusercontent.com',
  );

  bool loggedIn = false;
  bool busy = false;
  String? error;

  bool _googleSiap = false;
  GoogleSignIn? _google;

  Future<void> loginWithGoogle() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (googleClientId.isEmpty) {
        throw 'GOOGLE_CLIENT_ID belum diisi. Jalankan dengan '
            '--dart-define=GOOGLE_CLIENT_ID=...';
      }
      if (!_googleSiap) {
        _google = GoogleSignIn(
          scopes: const ['email'],
          serverClientId: googleClientId,
        );
        _googleSiap = true;
      }
      final akun = await _google!.signIn();
      if (akun == null) throw 'Masuk dibatalkan.';
      final idToken = (await akun.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw 'Google tidak mengirim id_token.';
      }

      final res = await api.post(
        '/api/v1/auth/google/token',
        body: {'id_token': idToken},
      );
      final data = (res as Map).cast<String, dynamic>();
      final pengguna = (data['pengguna'] as Map?) ?? const {};
      api.token = data['token'] as String?;
      repo.userName =
          (pengguna['nama_tampil'] ?? akun.displayName ?? 'Sobat MasakYuk')
              .toString();
      repo.userEmail = (pengguna['surel'] ?? akun.email ?? '').toString();
      loggedIn = true;
    } catch (e) {
      error = _pesan(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Mode tamu: masuk tanpa akun, data tidak tersinkron.
  void loginAsGuest() {
    repo.userName = 'Tamu';
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    if (api.token != null) {
      // Cabut token di server; gagal pun tetap keluar di app.
      api.post('/api/v1/auth/keluar').catchError((_) => null);
    }
    api.token = null;
    repo.logout();
    loggedIn = false;
    error = null;
    notifyListeners();
  }

  String _pesan(Object e) {
    if (e is String) return e;
    if (e is ApiException) return 'Gagal masuk (${e.status}). Coba lagi.';
    if (e is PlatformException) {
      // v6: DEVELOPER_ERROR = client Android (package + SHA-1) belum terdaftar.
      if (e.message?.contains('10:') ?? false) {
        return 'Client Android (package + SHA-1) belum terdaftar di '
            'Google Cloud.';
      }
      return 'Login Google gagal: ${e.message ?? e.code}';
    }
    debugPrint('Login Google error: $e');
    return 'Gagal masuk. Periksa koneksi ke server.';
  }
}
