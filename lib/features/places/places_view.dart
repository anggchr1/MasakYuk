import 'package:flutter/material.dart';
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
      return okQ && okK;
    }).toList();
    switch (_sort) {
      case 'Termurah':
        items.sort((a, b) =>
            _lowPrice(a).compareTo(_lowPrice(b)));
        break;
      case 'Paling Dekat':
        break; // butuh GPS — ditangani di onSelected
      default:
        items.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Makan & Belanja di Sekitar'),
            Text('Pasar, warung bahan & kuliner dekatmu',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(
                () => _q = v.toLowerCase().trim()),
            decoration: const InputDecoration(
              hintText: 'Cari pasar, warung, atau kedai...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Kategori Tempat',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolateMuted)),
              const Spacer(),
              Text('${items.length} Pilihan',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.chocolateMuted)),
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
                  child: ChoiceChip(
                    label: Text(k),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.sand,
                    labelStyle: TextStyle(
                        color: sel
                            ? Colors.white
                            : AppColors.chocolate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                    onSelected: (_) =>
                        setState(() => _kat = k),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Termurah', 'Paling Dekat', 'Rating Tertinggi']
                      .map((s) {
                final sel = _sort == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.sand,
                    labelStyle: TextStyle(
                        color: sel
                            ? Colors.white
                            : AppColors.chocolate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                    onSelected: (_) {
                      if (s == 'Paling Dekat') {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Sortir jarak aktif setelah izin lokasi (fitur GPS menyusul).')));
                        return;
                      }
                      setState(() => _sort = s);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((p) => Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(
                            place: p)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        color: AppColors.primaryContainer,
                        child: Stack(
                          children: [
                            Center(
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
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          9999),
                                ),
                                child: Text(p.jenis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            AppColors.primary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(p.nama,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                                '★ ${p.rating} (${p.ulasan} ulasan) • ${p.harga}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors
                                        .chocolateMuted)),
                            Text(p.desc,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceDetailScreen(
                                              place: p)),
                                ),
                                child: const Text(
                                    'Lihat Detail →'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.sand,
                    child: Icon(Icons.store,
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
                                fontWeight:
                                    FontWeight.w700)),
                        Text(
                            'Bantu sobat masak menemukan bahan segar.',
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
                        const Text('Daftar Sekarang ›'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
