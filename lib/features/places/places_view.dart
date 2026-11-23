import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/place_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/know.dart';
import 'place_detail_view.dart';

/// Makan di Sekitar: search + kategori + sortir + list + daftar warung.
/// Data: pasar & toko OpenStreetMap di sekitar GPS (tanpa seed contoh).
class PlacesScreen extends StatefulWidget {
  final RecipeRepository repo;
  const PlacesScreen({super.key, required this.repo});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  String _q = '';
  String _kat = 'Semua';
  final _ctrl = TextEditingController();
  Position? _pos;
  String _locLabel = 'Mencari lokasimu...';
  bool _locLoading = true;
  double _maxKm = 10;
  String? _placeErr;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    widget.repo.addListener(_onRepo);
    _fetchLoc();
  }

  /// Toko dari Overpass bisa datang menyusul; gambar ulang daftar.
  void _onRepo() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    _controller.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// GPS nyala saat buka section, lalu tarik tempat di sekitarnya.
  Future<void> _fetchLoc({bool paksa = false}) async {
    if (_fetching) return;
    _fetching = true;
    setState(() {
      _locLoading = true;
    });
    try {
      final r = await LocationService.current(segar: paksa);
      if (!mounted) return;
      setState(() {
        _pos = r.pos;
        _locLabel = r.locality;
      });
      await widget.repo.muatTempatSekitar(
          r.pos.latitude, r.pos.longitude,
          paksa: paksa);
      if (!mounted) return;
      setState(() {
        _locLoading = false;
        _placeErr = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_pos == null) _locLabel = '$e';
        _locLoading = false;
        _placeErr = '$e';
      });
    } finally {
      _fetching = false;
    }
  }

  double? _distOf(PlaceInfo p) => _pos == null
      ? null
      : LocationService.meters(_pos!, p.lat, p.lng);

  @override
  Widget build(BuildContext context) {
    final ada = {for (final p in widget.repo.places) p.jenis};
    final kats = [
      'Semua',
      for (final k in ['Tempat Makan', 'Kafe', 'Pasar'])
        if (ada.contains(k)) k,
    ];
    var items = widget.repo.places.where((p) {
      final okQ = _q.isEmpty ||
          p.nama.toLowerCase().contains(_q) ||
          p.jenis.toLowerCase().contains(_q);
      final okK = _kat == 'Semua' || p.jenis == _kat;
      final d = _distOf(p);
      final okD = _pos == null ||
          _maxKm >= 10 ||
          (d != null && d <= _maxKm * 1000);
      return okQ && okK && okD;
    }).toList();
    // Selalu terdekat dulu: radius + kategori sudah cukup sebagai filter.
    if (_pos != null) {
      items.sort((a, b) => _distOf(a)!.compareTo(_distOf(b)!));
    }
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            bottom: false,
            child: Container(
            padding: const EdgeInsets.fromLTRB(
                20, 24, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(
                                  9999),
                        ),
                        child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Makan & Belanja di Sekitar',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: Colors.white)),
                          Text(
                              'Pasar basah, warung bahan segar & kuliner dekatmu',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xFFFFC9B7))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(
                      () => _q = v.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText:
                        'Cari pasar, warung bumbu, atau kedai makan...',
                    hintStyle:
                        const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search,
                        color:
                            AppColors.chocolateMuted),
                    suffixIcon: GestureDetector(
                      onTap: () => _fetchLoc(paksa: true),
                      child: const Icon(
                          Icons.my_location_outlined,
                          color:
                              AppColors.chocolateMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _fetchLoc(paksa: true),
                  child: Row(
                    children: [
                      _locLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFC9B7),
                              ),
                            )
                          : const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFFFFC9B7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            _pos == null && !_locLoading
                                ? 'Lokasi saat ini: $_locLabel (ketuk untuk coba lagi)'
                                : 'Lokasi saat ini: $_locLabel',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFFFFC9B7))),
                      ),
                      const Icon(Icons.refresh,
                          size: 14,
                          color: Color(0xFFFFC9B7)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              const Text('Kategori Tempat',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chocolateMuted)),
              const Spacer(),
              Text('${kats.length - 1} Pilihan',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kats.map((k) {
                final sel = _kat == k;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _kat = k),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.sand,
                        borderRadius:
                            BorderRadius.circular(
                                9999),
                      ),
                      child: Text(k,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : AppColors.chocolate,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Jangkauan Radius',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chocolateMuted)),
              const Spacer(),
              Text(
                  _maxKm.isInfinite
                      ? 'Semua jarak'
                      : 'Maks. ${_maxKm.toInt()} km',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chocolateMuted)),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _distChip('Semua Jarak', double.infinity),
                _distChip('< 1 km', 1),
                _distChip('< 5 km', 5),
                _distChip('< 10 km', 10),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((p) => Container(
                margin:
                    const EdgeInsets.only(bottom: 16),
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
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors
                                .primaryContainer,
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                            child: SizedBox(
                              width: double.infinity,
                              child: AppImage(
                                url: placePhoto(p),
                                fallbackLetter: p.nama,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors
                                  .chocolate
                                  .withValues(
                                      alpha: 0.85),
                              borderRadius:
                                  BorderRadius.circular(
                                      9999),
                            ),
                            child: Text(p.jenis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white)),
                          ),
                        ),
                        if (_distOf(p) != null)
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                          horizontal:
                                              10,
                                          vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.secondary,
                                borderRadius:
                                    BorderRadius.circular(
                                        9999),
                              ),
                              child: Text(
                                  LocationService.label(
                                      _distOf(p)!),
                                  style:
                                      const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          letterSpacing:
                                              0.5,
                                          color: Colors
                                              .white)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(p.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color:
                                AppColors.chocolate)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        if (p.rating > 0) ...[
                        Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 14,
                                color: AppColors.amber),
                            const SizedBox(width: 4),
                            Text(
                                '${p.rating} (${p.ulasan} ulasan)',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700)),
                          ],
                        ),
                        const Text('•',
                            style: TextStyle(
                                color: Color(0xFFDEC0B7),
                                fontSize: 16)),
                        ],
                        if (p.harga.isNotEmpty)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFFFFE2D5),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: Text(p.harga,
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color:
                                      AppColors.secondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(p.desc,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 19.5 / 12,
                            color: AppColors
                                .chocolateMuted)),
                    const SizedBox(height: 8),
                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PlaceDetailScreen(
                                      place: p)),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(0, 40),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600),
                        ),
                        child: const Text(
                            'Lihat Detail →'),
                      ),
                    ),
                  ],
                ),
              )),
          if (items.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        _locLoading
                            ? 'Mencari pasar & tempat makan di sekitarmu...'
                            : _placeErr ??
                                (_pos == null
                                    ? 'Lokasi belum aktif. Ketuk "Lokasi saat ini" di atas untuk mengambil lokasi.'
                                    : 'Belum ada pasar/toko bernama di sekitar (±5 km).'),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.chocolateMuted)),
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
    );
  }

  /// Chip jarak ala Figma (aktif bila GPS & filter cocok).
  Widget _distChip(String label, double km) {
    final sel = _maxKm == km;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _maxKm = km),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.primary
                : AppColors.sand,
            borderRadius:
                BorderRadius.circular(9999),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: sel
                      ? Colors.white
                      : AppColors.chocolate)),
        ),
      ),
    );
  }
}
