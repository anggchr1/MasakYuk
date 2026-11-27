import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/place_photo.dart';
import '../../models/know.dart';

/// Detail tempat v2 — ikut Figma "15. Detail Tempat" (62:2889):
/// hero 320 + badge jam + judul + pil stat + rute + tentang +
/// andalan + jadwal. Tanpa peta embed & ulasan (tak ada datanya).
class PlaceDetailScreen extends StatefulWidget {
  final PlaceInfo place;
  const PlaceDetailScreen(
      {super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(
                height: 320,
                width: double.infinity,
                color: AppColors.sand,
                child: AppImage(
                  url: placePhoto(widget.place),
                  fallbackLetter: widget.place.nama,
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
                              widget.place.jam.isEmpty
                                  ? widget.place.jenis
                                  : '${widget.place.jenis} • ${widget.place.jam.split(',').first}',
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
              if (placePhotoIlustrasi(widget.place))
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text('Ilustrasi',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
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
                Text(widget.place.nama,
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
                        child: Text(widget.place.alamat,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors
                                    .chocolateMuted))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoPill(Icons.storefront_outlined, widget.place.jenis),
                    if (widget.place.jam.isNotEmpty)
                      _infoPill(
                          Icons.schedule_outlined, widget.place.jam),
                    if (widget.place.telepon.isNotEmpty)
                      GestureDetector(
                        onTap: () => launchUrl(
                            Uri.parse('tel:${widget.place.telepon}')),
                        child: _infoPill(Icons.call_outlined,
                            widget.place.telepon),
                      ),
                    if (widget.place.situs.isNotEmpty)
                      GestureDetector(
                        onTap: () => launchUrl(
                            Uri.parse(_url(widget.place.situs)),
                            mode: LaunchMode.externalApplication),
                        child: _infoPill(Icons.language,
                            _ringkas(widget.place.situs)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 18, color: AppColors.amber),
                    const SizedBox(width: 6),
                    Text(
                      widget.place.rating > 0
                          ? '${widget.place.rating} (${widget.place.ulasan} ulasan)'
                          : 'Belum ada rating',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate),
                    ),
                    if (widget.place.rating <= 0) ...[
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'OpenStreetMap belum menyediakan rating tempat.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.chocolateMuted),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.place.fasilitas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in widget.place.fasilitas)
                        _infoPill(
                            Icons.check_circle_outline, f),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (widget.place.harga.isNotEmpty)
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
                                '${widget.place.harga} — ${widget.place.hargaNote}',
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
                          'https://www.google.com/maps/dir/?api=1&destination=${widget.place.lat},${widget.place.lng}&travelmode=driving'),
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
                      Text(widget.place.desc,
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
                            Icon(Icons.map_outlined,
                                size: 14,
                                color:
                                    AppColors.primary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  'Sumber data: OpenStreetMap',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: AppColors
                                          .chocolateMuted)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.place.jam.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 16,
                          color: AppColors.chocolate),
                      SizedBox(width: 8),
                      Text('Jam Operasional',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.chocolate)),
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
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 18,
                            color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(widget.place.jam,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: AppColors
                                      .chocolate)),
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
    ));
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

  Widget _infoPill(IconData icon, String teks) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(teks,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chocolate)),
          ),
        ],
      ),
    );
  }

  static String _url(String s) =>
      s.startsWith('http') ? s : 'https://$s';

  static String _ringkas(String s) {
    final u = s
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
    return u.length > 32 ? '${u.substring(0, 32)}…' : u;
  }
}
