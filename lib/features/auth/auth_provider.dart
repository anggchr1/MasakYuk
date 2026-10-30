import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../data/recipe_repository.dart';

/// Login Google di app = login Google di web:
/// id_token Google → POST /api/v1/auth/google/token → token Sanctum.
///
/// Sesi disimpan di perangkat supaya tidak perlu login tiap buka app,
/// tapi kedaluwarsa setelah [_masaBerlaku] jam.
class AuthProvider extends ChangeNotifier {
  final RecipeRepository repo;
  final ApiClient api;
  AuthProvider(this.repo, {ApiClient? api})
      : api = api ?? repo.api;

  /// Harus sama dengan GOOGLE_CLIENT_ID di .env backend.
  /// Default = client ID milik project temanmu (sama dengan backend).
  /// Bisa diganti saat build:
  ///   flutter run --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '860000695247-luiafd1ap03006k4j8ulvs8mt5g8itgf.apps.googleusercontent.com',
  );

  /// Umur sesi sebelum wajib login ulang.
  static const masaBerlaku = Duration(hours: 12);

  bool loggedIn = false;
  bool busy = false;
  bool siap = false; // sesi tersimpan sudah dicek saat app dibuka
  bool isGuest = false;
  String? error;

  bool _googleSiap = false;
  GoogleSignIn? _google;

  static const _kToken = 'sesi.token';
  static const _kKedaluwarsa = 'sesi.kedaluwarsa';
  static const _kNama = 'sesi.nama';
  static const _kSurel = 'sesi.surel';

  /// Dipanggil sekali saat app dibuka.
  Future<void> muatSesi() async {
    try {
      final p = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final token = p.getString(_kToken);
      final kedaluwarsa = p.getInt(_kKedaluwarsa);
      if (token != null &&
          token.isNotEmpty &&
          kedaluwarsa != null &&
          DateTime.now().millisecondsSinceEpoch < kedaluwarsa) {
        api.token = token;
        repo.userName = p.getString(_kNama) ?? 'Sobat MasakYuk';
        repo.userEmail = p.getString(_kSurel) ?? '';
        loggedIn = true;
      } else if (token != null) {
        await p.clear(); // sesi lewat masa berlaku
      }
    } catch (e) {
      debugPrint('Gagal memuat sesi: $e');
    } finally {
      siap = true;
      notifyListeners();
    }
  }

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
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw 'Server tidak mengirim token.';
      }
      api.token = token;
      repo.userName =
          (pengguna['nama_tampil'] ?? akun.displayName ?? 'Sobat MasakYuk')
              .toString();
      repo.userEmail = (pengguna['surel'] ?? akun.email ?? '').toString();
      isGuest = false;
      loggedIn = true;
      await _simpanSesi(token);
      await repo.muatResepMilikku();
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
    repo.userEmail = '';
    isGuest = true;
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
    isGuest = false;
    error = null;
    _hapusSesi();
    notifyListeners();
  }

  Future<void> _simpanSesi(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setInt(
      _kKedaluwarsa,
      DateTime.now().add(masaBerlaku).millisecondsSinceEpoch,
    );
    await p.setString(_kNama, repo.userName);
    await p.setString(_kSurel, repo.userEmail);
  }

  Future<void> _hapusSesi() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kKedaluwarsa);
    await p.remove(_kNama);
    await p.remove(_kSurel);
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
