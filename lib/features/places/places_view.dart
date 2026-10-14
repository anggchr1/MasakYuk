import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/recipe_repository.dart';
import '../../models/know.dart';
import 'place_detail_view.dart';

/// Makan di Sekitar: search + kategori + sortir + list + daftar warung.
/// Jarak & GPS = teknis belakangan: radius/sortir jarakКонечно toast jujur.
/// Data: assets/places.json (seed contoh, ganti Overpass live belakangan).
class PlacesScreen extends StatefulWidget {
  final RecipeRepository repo;
  const PlacesScreen({super.key, required this.repo});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  String _q = '';
  String _kat = 'Semua';
  String _sort = 'Rating Tertinggi';
  final _ctrl = TextEditingController();
  Position? _pos;
  String _locLabel = 'Mencari lokasimu...';
  bool _locLoading = true;
  double _maxKm = 10;

  @override
  void initState() {
    super.initState();
    _fetchLoc();
  }

  /// GPS nyala saat buka section (sesuai Figma: lokasi saat ini).
  Future<void> _fetchLoc() async {
    setState(() {
      _locLoading = true;
    });
    try {
      final r = await LocationService.current();
      if (!mounted) return;
      setState(() {
        _pos = r.pos;
        _locLabel = r.locality;
        _locLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pos = null;
        _locLabel = '$e';
        _locLoading = false;
      });
    }
  }

  double? _distOf(PlaceInfo p) => _pos == null
      ? null
      : LocationService.meters(_pos!, p.lat, p.lng);

  int _lowPrice(PlaceInfo p) {
    final m =
        RegExp(r'Rp([\d.]+)').firstMatch(p.harga.replaceAll(' ', ''));
    if (m == null) return 999999999;
    return int.tryParse(m.group(1)!.replaceAll('.', '')) ??
        999999999;
  }

  @override
  Widget build(BuildContext context) {
    final kats = [
      'Semua',
      ...{for (final p in widget.repo.places) p.jenis}
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
    switch (_sort) {
      case 'Termurah':
        items.sort((a, b) =>
            _lowPrice(a).compareTo(_lowPrice(b)));
        break;
      case 'Paling Dekat':
        if (_pos != null) {
          items.sort((a, b) => _distOf(a)!
              .compareTo(_distOf(b)!));
        }
        break;
      default:
        items.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return Scaffold(
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
                      onTap: _fetchLoc,
                      child: const Icon(
                          Icons.my_location_outlined,
                          color:
                              AppColors.chocolateMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _fetchLoc,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius:
                  BorderRadius.circular(9999),
            ),
            child: Row(
              children:
                  ['Termurah', 'Paling Dekat', 'Rating Tertinggi']
                      .map((s) {
                final sel = _sort == s;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (s == 'Paling Dekat' &&
                          _pos == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                                content: Text(
                                    _locLoading
                                        ? 'Menunggu GPS...'
                                        : 'GPS: $_locLabel')));
                        return;
                      }
                      setState(() => _sort = s);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(
                                9999),
                      ),
                      child: Text(s,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? const Color(
                                      0xFF7F2500)
                                  : AppColors
                                      .chocolateMuted)),
                    ),
                  ),
                );
              }).toList(),
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
                          child: Center(
                            child: Text(
                              p.nama.isEmpty
                                  ? '?'
                                  : p.nama[0],
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: Colors.white70),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEAE0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Daftarkan Warung Dapurmu',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700)),
                      Text(
                          'Bantu sobat masak menemukan bahan segar di sekitarmu.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors
                                  .chocolateMuted)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text(
                                  'Pendaftaran warung dibuka segera.'))),
                  child:
                      const Text('Daftar Sekarang ›',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700)),
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
