import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/push/push_service.dart';
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

  /// Pesan akun yang ditahan (akun baru / akun dihapus) sampai aktivasi
  /// selesai. Ditampilkan sebagai popup di layar login.
  String? tertahan;

  /// True bila akun yang ditahan adalah akun yang dihapus dan bisa
  /// diaktifkan kembali dari aplikasi (layar reaktivasi OTP).
  bool perluReaktivasi = false;

  /// Email akun yang ditahan, untuk mengisi otomatis kolom email.
  String? surelTertahan;

  /// Pesan info di layar login, mis. setelah akun dihapus.
  String? info;

  bool _googleSiap = false;
  GoogleSignIn? _google;

  static const _kToken = 'sesi.token';
  static const _kKedaluwarsa = 'sesi.kedaluwarsa';
  static const _kNama = 'sesi.nama';
  static const _kSurel = 'sesi.surel';
  static const _kFoto = 'sesi.foto';

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
        repo.userAvatarUrl = p.getString(_kFoto);
        loggedIn = true;
        _refreshProfil(); // nama/foto terbaru dari server (gagal = pakai cache)
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
    tertahan = null;
    perluReaktivasi = false;
    surelTertahan = null;
    info = null;
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
      final akun = await _pilihAkunGoogle();
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
      await _masukSebagai(
        pengguna,
        token,
        namaCadangan: akun.displayName,
        surelCadangan: akun.email,
      );
    } catch (e) {
      final pesan = _pesan(e);
      if (e is ApiException && e.status == 403) {
        final info = infoReaktivasiDariBody(e.body);
        tertahan = pesan;
        perluReaktivasi = info.perlu;
        surelTertahan = info.surel;
      } else {
        error = pesan;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Minta kode OTP reaktivasi dikirim ke email akun yang dinonaktifkan.
  Future<bool> kirimOtp(String surel) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.post(
        '/api/v1/auth/reaktivasi/kirim',
        body: {'surel': surel},
      );
      return true;
    } catch (e) {
      error = _pesan(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Cocokkan kode OTP; bila benar akun aktif lagi dan langsung masuk.
  Future<bool> verifikasiOtp(String surel, String kode) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post(
        '/api/v1/auth/reaktivasi/verifikasi',
        body: {'surel': surel, 'kode': kode},
      );
      final data = (res as Map).cast<String, dynamic>();
      final pengguna = (data['pengguna'] as Map?) ?? const {};
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw 'Server tidak mengirim token.';
      }
      await _masukSebagai(pengguna, token, surelCadangan: surel);
      return true;
    } catch (e) {
      error = _pesan(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Kembali dari layar reaktivasi ke layar login biasa.
  void batalkanReaktivasi() {
    perluReaktivasi = false;
    surelTertahan = null;
    tertahan = null;
    error = null;
    notifyListeners();
  }

  /// Simpan sesi setelah login berhasil (Google maupun OTP reaktivasi).
  Future<void> _masukSebagai(
    Map pengguna,
    String token, {
    String? namaCadangan,
    String? surelCadangan,
  }) async {
    api.token = token;
    repo.userName =
        (pengguna['nama_tampil'] ?? namaCadangan ?? 'Sobat MasakYuk').toString();
    repo.userEmail = (pengguna['surel'] ?? surelCadangan ?? '').toString();
    repo.userAvatarUrl = ((pengguna['foto'] as Map?)?['url'])?.toString();
    isGuest = false;
    loggedIn = true;
    perluReaktivasi = false;
    tertahan = null;
    surelTertahan = null;
    await _simpanSesi(token);
    await repo.muatResepMilikku();
    await repo.muatFavorit();
    await repo.muatNotifikasi();
    await PushService.daftarkan(repo);
  }

  /// Selalu tampilkan pemilih akun Google.
  /// Tanpa `signOut` dulu, plugin memakai akun terakhir yang tersimpan
  /// di perangkat sehingga user tak bisa ganti akun.
  Future<GoogleSignInAccount?> _pilihAkunGoogle() async {
    try {
      await _google!.signOut();
    } catch (_) {
      // sesi Google lokal memang sudah kosong
    }
    return _google!.signIn();
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
    PushService.lepas();
    api.token = null;
    repo.logout();
    repo.muatUlangPublik(); // daftar tamu memuat resep yang baru terbit
    loggedIn = false;
    isGuest = false;
    error = null;
    tertahan = null;
    perluReaktivasi = false;
    surelTertahan = null;
    info = null;
    _hapusSesi();
    notifyListeners();
  }

  /// Hapus akun di server (lunak + cabut token), lalu bersihkan sesi lokal.
  Future<void> hapusAkun() async {
    final res = await api.delete('/api/v1/saya');
    final pesan = res is Map ? res['pesan']?.toString() : null;
    await PushService.lepas();
    api.token = null;
    repo.logout();
    repo.muatUlangPublik();
    loggedIn = false;
    isGuest = false;
    error = null;
    tertahan = null;
    perluReaktivasi = false;
    surelTertahan = null;
    info = pesan;
    await _hapusSesi();
    notifyListeners();
  }

  Future<void> _simpanSesi(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setInt(
      _kKedaluwarsa,
      DateTime.now().add(masaBerlaku).millisecondsSinceEpoch,
    );
    await simpanProfil();
  }

  /// Simpan nama/foto profil terbaru (dipanggil setelah edit profil).
  Future<void> simpanProfil() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kNama, repo.userName);
    await p.setString(_kSurel, repo.userEmail);
    final foto = repo.userAvatarUrl;
    if (foto == null || foto.isEmpty) {
      await p.remove(_kFoto);
    } else {
      await p.setString(_kFoto, foto);
    }
  }

  /// Ambil nama/foto terbaru dari server setelah sesi dipulihkan.
  Future<void> _refreshProfil() async {
    try {
      final j = (await api.get('/api/v1/saya') as Map).cast<String, dynamic>();
      repo.userName = (j['nama_tampil'] ?? repo.userName).toString();
      repo.userEmail = (j['surel'] ?? repo.userEmail).toString();
      repo.userAvatarUrl = ((j['foto'] as Map?)?['url'])?.toString();
      await simpanProfil();
      notifyListeners();
    } catch (_) {
      // Offline / server mati: tetap pakai data cache di perangkat.
    }
  }

  Future<void> _hapusSesi() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kKedaluwarsa);
    await p.remove(_kNama);
    await p.remove(_kSurel);
    await p.remove(_kFoto);
  }

  String _pesan(Object e) {
    if (e is String) return e;
    if (e is ApiException) {
      final dariServer = pesanApiDariBody(e.body);
      if (dariServer != null) return dariServer;
      if (e.status == 403) {
        return 'Akun belum bisa masuk. Cek email untuk link aktivasi, '
            'atau aktifkan kembali akun yang dinonaktifkan.';
      }
      return 'Gagal masuk (${e.status}). Coba lagi.';
    }
    if (e is PlatformException) {
      final m = e.message ?? '';
      // v6: DEVELOPER_ERROR = client Android (package + SHA-1) belum terdaftar.
      if (m.contains('10:')) {
        return 'Client Android (package + SHA-1) belum terdaftar di '
            'Google Cloud.';
      }
      // NETWORK_ERROR: HP tidak bisa menghubungi layanan Google.
      if (m.contains('7:')) {
        return 'Google tidak bisa dihubungi dari HP ini (NETWORK_ERROR). '
            'Coba data seluler, matikan VPN/Private DNS, dan pastikan '
            'akun Google + Play Services aktif.';
      }
      return 'Login Google gagal: ${e.message ?? e.code}';
    }
    debugPrint('Login Google error: $e');
    return 'Server tidak bisa dihubungi ($apiBaseUrl). '
        'Pastikan HP & PC satu Wi-Fi dan backend jalan di 0.0.0.0:8000.';
  }
}

/// Ambil `pesan`/`message` dari body error API (JSON), atau null.
/// Backend mengirim pesan akun tertahan lewat `{"pesan": "..."}`.
String? pesanApiDariBody(String body) {
  final j = _jsonBody(body);
  if (j != null) {
    final p = j['pesan'] ?? j['message'];
    if (p is String && p.trim().isNotEmpty) return p.trim();
  }
  return null;
}

/// Info reaktivasi dari body 403 API: perlu/tidak, email akun, dan URL web.
({bool perlu, String? surel, String? url}) infoReaktivasiDariBody(String body) {
  final j = _jsonBody(body);
  String? teks(Object? v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  return (
    perlu: j?['reaktivasi'] == true,
    surel: teks(j?['surel']),
    url: teks(j?['url_reaktivasi']),
  );
}

Map<String, dynamic>? _jsonBody(String body) {
  try {
    final j = json.decode(body);
    if (j is Map) return j.cast<String, dynamic>();
  } catch (_) {
    // Bukan JSON (mis. halaman HTML 404): pakai pesan umum.
  }
  return null;
}
