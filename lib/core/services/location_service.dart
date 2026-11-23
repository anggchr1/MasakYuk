import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// GPS: izin + posisi sekali + nama lokalitas + jarak.
/// Gagal = throw pesan ramah (GPS mati / izin ditolak).
class LocResult {
  final Position pos;
  final String locality;
  LocResult(this.pos, this.locality);
}

class LocationService {
  static LocResult? _cache;
  static DateTime? _cacheAt;

  /// Minta izin lebih awal (mis. saat app dibuka) tanpa menunggu GPS fix.
  /// Tidak melempar error: hasil izin tetap ditangani saat lokasi dipakai.
  static Future<void> mintaIzin() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      // izin ditolak / layanan tak tersedia → ditangani di current()
    }
  }

  /// [segar] = abaikan cache 60 detik (dipakai tombol muat ulang).
  static Future<LocResult> current({bool segar = false}) async {
    final c = _cache;
    if (!segar &&
        c != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) <
            const Duration(seconds: 60)) {
      return c;
    }
    final enabled =
        await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw 'Nyalakan GPS perangkat dulu.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw 'Izin lokasi ditolak.';
    }
    if (perm == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen — buka Pengaturan.';
    }
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } on TimeoutException {
      // Hanya pakai posisi terakhir kalau masih baru; posisi lama membuat
      // peta menampilkan lokasi yang jauh dari tempat user sebenarnya.
      final last = await Geolocator.getLastKnownPosition();
      final umur = last == null
          ? null
          : DateTime.now().difference(last.timestamp);
      if (last == null ||
          umur == null ||
          umur > const Duration(minutes: 2)) {
        throw 'GPS belum dapat sinyal. Coba di area terbuka.';
      }
      pos = last;
    }
    var locality =
        '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
    try {
      final marks = await Geocoding()
          .placemarkFromCoordinates(
              pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        final parts = [m.subLocality, m.locality]
            .where(
                (s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
        if (parts.isNotEmpty) {
          locality = parts.join(', ');
        }
      }
    } catch (_) {
      // nama daerah opsional — koordinat tetap dipakai
    }
    _cache = LocResult(pos, locality);
    _cacheAt = DateTime.now();
    return _cache!;
  }

  static double meters(
          Position a, double lat, double lng) =>
      Geolocator.distanceBetween(
          a.latitude, a.longitude, lat, lng);

  static String label(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}
