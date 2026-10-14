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
  static Future<LocResult> current() async {
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
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
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
    return LocResult(pos, locality);
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
