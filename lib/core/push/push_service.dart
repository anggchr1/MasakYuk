// ignore_for_file: deprecated_member_use
// getToken/onTokenRefresh/deleteToken deprecated demi API FID baru; backend
// masih mengirim lewat FCM v1 yang memakai registration token.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/recipe_repository.dart';

/// Push FCM: daftarkan token perangkat saat login, segarkan daftar
/// notifikasi saat pesan masuk. Gagal inisialisasi = app tetap jalan.
class PushService {
  PushService._();

  static bool _aktif = false;
  static RecipeRepository? _repo;
  static StreamSubscription<String>? _tokenSub;

  /// Panggil sekali sebelum runApp.
  static Future<void> inisialisasi() async {
    try {
      await Firebase.initializeApp();
      _aktif = true;
      // App sedang terbuka: tidak ada notifikasi sistem, cukup segarkan data.
      FirebaseMessaging.onMessage.listen((_) => _repo?.muatNotifikasi());
      FirebaseMessaging.onMessageOpenedApp
          .listen((_) => _repo?.muatNotifikasi());
    } catch (e) {
      debugPrint('Push tidak aktif: $e');
    }
  }

  /// Daftarkan token perangkat ke akun yang baru login.
  static Future<void> daftarkan(RecipeRepository repo) async {
    _repo = repo;
    if (!_aktif) return;
    try {
      // Android 13+: memunculkan dialog izin notifikasi.
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await repo.daftarkanPerangkat(token);
      _tokenSub ??= FirebaseMessaging.instance.onTokenRefresh
          .listen(repo.daftarkanPerangkat);
    } catch (e) {
      debugPrint('Gagal mendaftarkan perangkat: $e');
    }
  }

  /// Logout: token dibuang supaya push tidak nyasar ke akun lama.
  static Future<void> lepas() async {
    _repo = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    if (!_aktif) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Gagal melepas token push: $e');
    }
  }
}
