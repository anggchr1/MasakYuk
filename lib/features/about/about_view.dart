import 'package:flutter/material.dart';
import '../../core/app_version.dart';
import '../../core/theme/app_theme.dart';

/// Pusat info aplikasi: dua pilihan (tentang APK & lisensi pustaka).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            title: 'Tentang Aplikasi',
            subtitle: 'MasakYuk $appVersion',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFDEC0B7)
                            .withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFFFFEAE0),
                        child: Icon(Icons.restaurant_menu,
                            size: 32, color: AppColors.primary),
                      ),
                      SizedBox(height: 12),
                      Text('MasakYuk',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.chocolate)),
                      SizedBox(height: 4),
                      Text(
                        'Resep rumahan, anggaran belanja, dan tempat bahan segar di sekitarmu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            height: 19.5 / 12,
                            color: AppColors.chocolateMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _menu(
                  icon: Icons.phone_android,
                  title: 'Tentang APK Ini',
                  desc: 'Fitur, sumber data, dan cara kerja aplikasi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TentangApkScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _menu(
                  icon: Icons.article_outlined,
                  title: 'Lisensi & Sumber Data',
                  desc: 'Pustaka open source dan atribusi data',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LisensiScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(appVersion,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors.chocolateMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFFDEC0B7)
                  .withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEAE0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate)),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.chocolateMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.chocolateMuted),
          ],
        ),
      ),
    );
  }
}

/// Isi "Tentang APK Ini": versi, fitur, sumber data, dan catatan.
class TentangApkScreen extends StatelessWidget {
  const TentangApkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Tentang APK Ini',
      subtitle: 'MasakYuk $appVersion',
      children: [
        _card('Apa itu MasakYuk?', const [
          'MasakYuk membantu memasak rumahan: cari resep dari bahan yang ada, '
              'hitung perkiraan biaya, dan temukan pasar atau warung bahan segar '
              'di sekitar lokasi.',
        ]),
        _card('Fitur utama', const [
          '• Resep rumahan dengan pencocokan bahan',
          '• Perkiraan anggaran belanja per porsi',
          '• Ensiklopedia bahan dari Wikipedia',
          '• Tempat makan & belanja sekitar via OpenStreetMap',
          '• Simpan favorit, komentar, dan notifikasi komunitas',
        ]),
        _card('Sumber data', const [
          'Resep dan akun berasal dari server MasakYuk. Data tempat diambil '
              'dari OpenStreetMap, ensiklopedia dari Wikipedia, dan harga '
              'merupakan estimasi pasar lokal — bukan harga resmi toko.',
        ]),
        const SizedBox(height: 20),
        const Text(appVersion,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
                color: AppColors.chocolateMuted)),
      ],
    );
  }
}

/// Daftar pustaka open source + atribusi data.
class LisensiScreen extends StatelessWidget {
  const LisensiScreen({super.key});

  static const _aplikasi = [
    ('Flutter', 'BSD-3-Clause', 'Kerangka aplikasi dan widget UI.'),
    ('Dart', 'BSD-3-Clause', 'Bahasa pemrograman aplikasi.'),
  ];

  static const _data = [
    ('OpenStreetMap', 'ODbL 1.0',
        'Data peta, tempat makan, dan toko. © kontributor OpenStreetMap.'),
    ('Nominatim', 'ODbL 1.0',
        'Pencarian tempat berdasarkan koordinat (layanan OpenStreetMap).'),
    ('Overpass API', 'ODbL 1.0',
        'Data toko dan fasilitas sekitar dari OpenStreetMap.'),
    ('Wikipedia', 'CC BY-SA 4.0',
        'Ringkasan bahan dan masakan di ensiklopedia.'),
  ];

  static const _pustaka = [
    ('geolocator', 'MIT', 'Lokasi GPS perangkat.'),
    ('geocoding', 'MIT', 'Nama daerah dari koordinat.'),
    ('http', 'BSD-3-Clause', 'Permintaan ke API MasakYuk.'),
    ('shared_preferences', 'BSD-3-Clause', 'Penyimpanan sesi dan cache lokal.'),
    ('url_launcher', 'BSD-3-Clause', 'Membuka telepon, situs, dan rute.'),
    ('share_plus', 'BSD-3-Clause', 'Berbagi resep ke aplikasi lain.'),
    ('google_sign_in', 'Apache-2.0', 'Masuk dengan akun Google.'),
    ('firebase_core', 'BSD-3-Clause', 'Dasar layanan Firebase.'),
    ('firebase_messaging', 'BSD-3-Clause', 'Notifikasi push komentar.'),
    ('timeago', 'MIT', 'Waktu relatif pada notifikasi.'),
    ('google_fonts', 'Apache-2.0', 'Tipografi aplikasi.'),
    ('flutter_svg', 'MIT', 'Ikon dan gambar SVG.'),
    ('image_picker', 'Apache-2.0', 'Memilih foto resep.'),
    ('gal', 'MIT', 'Menyimpan gambar ke galeri.'),
    ('path_provider', 'BSD-3-Clause', 'Folder penyimpanan sementara.'),
    ('screenshot', 'MIT', 'Membagikan resep sebagai gambar.'),
    ('cupertino_icons', 'MIT', 'Ikon gaya iOS.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Lisensi & Sumber Data',
      subtitle: 'Pustaka open source yang dipakai',
      children: [
        _group('Aplikasi', _aplikasi),
        _group('Sumber data', _data),
        _group('Pustaka Dart & Flutter', _pustaka),
        const SizedBox(height: 8),
        const Text(
          'Daftar ini mencakup komponen utama. Teks lisensi lengkap tiap '
          'pustaka tersedia di repositori resminya masing-masing.',
          style: TextStyle(
              fontSize: 12,
              height: 19.5 / 12,
              color: AppColors.chocolateMuted),
        ),
      ],
    );
  }

  Widget _group(String judul, List<(String, String, String)> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.chocolateMuted)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: const Color(0xFFDEC0B7)
                            .withValues(alpha: 0.2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item.$1,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.chocolate)),
                              Text(item.$3,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 18 / 12,
                                      color: AppColors.chocolateMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius:
                                BorderRadius.circular(9999),
                          ),
                          child: Text(item.$2,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.chocolateMuted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kerangka halaman: header coklat melengkung + isi.
class _Shell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _Shell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(title: title, subtitle: subtitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF7F2500),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Icon(Icons.arrow_back,
                    size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.55,
                          color: Colors.white)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFB59C))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _card(String judul, List<String> isi) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chocolate)),
          const SizedBox(height: 6),
          for (final p in isi)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(p,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 19.5 / 13,
                      color: AppColors.chocolateMuted)),
            ),
        ],
      ),
    ),
  );
}
