import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/know.dart';

/// Detail tempat v2 — ikut Figma "15. Detail Tempat" (62:2889):
/// hero 320 + badge jam + judul + pil stat + rute + tentang +
/// andalan + jadwal. Tanpa peta embed & ulasan (tak ada datanya).
class PlaceDetailScreen extends StatelessWidget {
  final PlaceInfo place;
  const PlaceDetailScreen(
      {super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(
                height: 320,
                width: double.infinity,
                color: AppColors.sand,
                child: Center(
                  child: Text(
                    place.nama.isEmpty
                        ? '?'
                        : place.nama[0],
                    style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDEC0B7)),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.6),
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.2),
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 16,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _floatBtn(context, Icons.arrow_back,
                          () => Navigator.pop(context)),
                      const Spacer(),
                      _floatBtn(
                          context,
                          Icons.bookmark_border,
                          () => ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Bookmark tempat aktif di versi berikutnya.')))),
                      const SizedBox(width: 8),
                      _floatBtn(
                          context,
                          Icons.share_outlined,
                          () => SharePlus.instance.share(
                                ShareParams(
                                    text:
                                        '${place.nama}\n${place.alamat}\n\n— via MasakYuk'),
                              )),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.chocolate
                          .withValues(alpha: 0.85),
                      borderRadius:
                          BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                              '${place.jenis} • ${place.jam.isEmpty ? 'Buka setiap hari' : place.jam.split(',').first}',
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.275,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(place.nama,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.65,
                        color: AppColors.chocolate)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 15,
                        color: AppColors.chocolateMuted),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(place.alamat,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors
                                    .chocolateMuted))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statPill(
                          Icons.near_me_outlined,
                          'JARAK TEMPUH',
                          'Aktifkan lokasi',
                          'untuk jarak akurat'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statPill(
                          Icons.star_outline,
                          'REKAN MASAK',
                          '★ ${place.rating}',
                          '(${place.ulasan} ulasan)'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.secondary
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color:
                                AppColors.secondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Rentang Belanja Bumbu',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors
                                        .chocolateMuted)),
                            Text(
                                '${place.harga} — ${place.hargaNote}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors
                                        .chocolate)),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(
                                  9999),
                        ),
                        child: const Text(
                            'harga pasar • estimasi',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}&travelmode=driving'),
                      mode:
                          LaunchMode.externalApplication,
                    ),
                    icon: const Icon(
                        Icons.navigation_outlined,
                        size: 18),
                    label: const Text(
                        'Rute di Google Maps',
                        style:
                            TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                      'Membuka navigasi langsung di aplikasi peta perangkat Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.chocolateMuted)),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 16,
                        color: AppColors.chocolate),
                    SizedBox(width: 8),
                    Text('Tentang Tempat Ini',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(place.desc,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 22.75 / 14,
                              color:
                                  AppColors.chocolate)),
                      const SizedBox(height: 12),
                      Container(
                        padding:
                            const EdgeInsets.only(
                                top: 13),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: const Color(
                                        0xFFDEC0B7)
                                    .withValues(
                                        alpha: 0.4)),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified,
                                size: 14,
                                color:
                                    AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                                'Diverifikasi Komunitas MasakYuk',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: AppColors
                                        .chocolateMuted)),
                            Spacer(),
                            Text('Tradisional',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors
                                        .chocolate)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                        Icons.shopping_basket_outlined,
                        size: 16,
                        color: AppColors.chocolate),
                    const SizedBox(width: 8),
                    const Text('Bahan & Menu Andalan',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    const Spacer(),
                    Text(
                        '${place.unggulan.length} Bahan Utama',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors
                                .chocolateMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                ...place.unggulan.map((u) => Container(
                      margin:
                          const EdgeInsets.only(
                              bottom: 10),
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.shopping_basket,
                                size: 18,
                                color:
                                    AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(u.nama,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: AppColors
                                            .chocolate)),
                                Text(u.desc,
                                    maxLines: 2,
                                    overflow: TextOverflow
                                        .ellipsis,
                                    style:
                                        const TextStyle(
                                            fontSize: 12,
                                            color: AppColors
                                                .chocolateMuted)),
                              ],
                            ),
                          ),
                          Text(u.harga,
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors
                                      .chocolate)),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 16,
                        color: AppColors.chocolate),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Jadwal & Waktu Terbaik Belanja',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color:
                                  AppColors.chocolate)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.access_time,
                                size: 18,
                                color:
                                    AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                      place.jam.isEmpty
                                          ? 'Jam operasional: setiap hari'
                                          : 'Jam operasional: ${place.jam}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight
                                                  .w700)),
                                  const Text(
                                      'Buka setiap hari (Senin s/d Minggu)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .chocolateMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding:
                            const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFE2D5)
                                  .withValues(
                                      alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(
                                      0xFFFF9F59)
                                  .withValues(
                                      alpha: 0.3)),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                                Icons
                                    .tips_and_updates_outlined,
                                size: 16,
                                color:
                                    AppColors.chocolate),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                      'Rekomendasi Waktu Belanja:',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight
                                                  .w700)),
                                  Text(
                                      'Datang pagi untuk pilihan tersegar dan harga terbaik.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          height:
                                              19.5 / 12,
                                          color: AppColors
                                              .chocolate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatBtn(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Icon(icon,
            size: 20, color: AppColors.chocolate),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, String big,
      String small) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors
                            .chocolateMuted)),
                Text(big,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chocolate)),
                Text(small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .chocolateMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
