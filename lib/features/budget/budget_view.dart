import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';

/// Hasil budget: header editable + sortir + rincian harga + tempat.
/// Range ±25%: budget 20k → 15–25k. Tak lengkap = label + di belakang.
class BudgetScreen extends StatefulWidget {
  final RecipeRepository repo;
  final int budget;
  const BudgetScreen(
      {super.key, required this.repo, required this.budget});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late int _budget;
  String _sort = 'Termurah';
  static const _sorts = ['Termurah', 'Paling Cepat', 'Rating Tertinggi'];

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        if (!widget.repo.loaded) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()));
        }
        var items = widget.repo.budgetSearch(_budget);
        switch (_sort) {
          case 'Paling Cepat':
            items.sort((a, b) => a.stepsList.length
                .compareTo(b.stepsList.length));
            break;
          case 'Rating Tertinggi':
            items.sort(
                (a, b) => b.loves.compareTo(a.loves));
            break;
          default:
            break; // repo sudah urut termurah
        }
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
              Row(
                children: [
                  const Text('URUTKAN RESEP',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color:
                              AppColors.chocolateMuted)),
                  const Spacer(),
                  Text('${items.length} Menu Ditemukan',
                      style: const TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.chocolateMuted)),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sorts.map((s) {
                    final sel = _sort == s;
                    final icon = s == 'Termurah'
                        ? Icons.sell_outlined
                        : s == 'Paling Cepat'
                            ? Icons.timer_outlined
                            : Icons.star_outline;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _sort = s),
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
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 15,
                                  color: sel
                                      ? Colors.white
                                      : AppColors
                                          .chocolate),
                              const SizedBox(width: 6),
                              Text(s,
                                  style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : AppColors
                                              .chocolate,
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.sand
                      .withValues(alpha: 0.8),
                  borderRadius:
                      BorderRadius.circular(48),
                  border: Border.all(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.4)),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18,
                        color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Semua biaya didasarkan pada harga pasar tradisional & warung sayur terdekat di wilayah Anda. Nilai bertanda estimasi dihitung per porsi masak harian.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 19.5 / 12,
                            color: AppColors
                                .chocolateMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Tidak ada menu dalam budget ini.\nNaikkan budget atau tambah resep sendiri.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.chocolateMuted),
                  ),
                ),
              ...items.map((r) => _budgetCard(r)),
              _placesSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Header #7F2500 ala Figma: kembali + judul + avatar + kapsul budget.
  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF7F2500),
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
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Pencarian Terpantau',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB59C))),
                    Text('Budget Maksimal',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              const Color(0xFFFFB59C),
                          width: 2),
                    ),
                    child: ClipOval(
                      child: AppImage(
                        url: FoodPhotos.avatar,
                        fallbackLetter:
                            widget.repo.userName,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star,
                          size: 10,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(
                13, 17, 13, 13),
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(Money.rp(_budget),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                              color: Colors.white)),
                      const Text(
                          'Target belanja harian keluarga',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFFFFB59C))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _change,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius:
                          BorderRadius.circular(9999),
                    ),
                    child: const Text('Ubah',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color:
                                AppColors.chocolate)),
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

  /// Tempat beli bahan di sekitar (pintasan ke layar peta).
  Widget _placesSection() {
    final ps = widget.repo.places.take(2).toList();
    if (ps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Tempat Beli Bahan di Sekitar',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text('Rekomendasi pasar & warung fisik terdekat',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors
                                .chocolateMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius:
                      BorderRadius.circular(9999),
                ),
                child: const Text('Aktif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ps.map((p) => Container(
                margin:
                    const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              const BoxDecoration(
                            color: AppColors.sand,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.store,
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
                              Text(p.nama,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: AppColors
                                          .chocolate)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                                horizontal:
                                                    8,
                                                vertical:
                                                    2),
                                    decoration:
                                        BoxDecoration(
                                      color: AppColors
                                          .sand,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  9999),
                                    ),
                                    child: Text(p.jenis,
                                        style:
                                            const TextStyle(
                                                fontSize:
                                                    11,
                                                fontWeight:
                                                    FontWeight
                                                        .w600)),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                                horizontal:
                                                    8,
                                                vertical:
                                                    2),
                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                          0xFFFFEAE0),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  9999),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        const Icon(
                                            Icons.star,
                                            size: 12,
                                            color: AppColors
                                                .amber),
                                        const SizedBox(
                                            width: 2),
                                        Text(
                                            '${p.rating} (${p.ulasan})',
                                            style:
                                                const TextStyle(
                                                    fontSize:
                                                        11,
                                                    fontWeight:
                                                        FontWeight
                                                            .w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.desc,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors
                                .chocolateMuted)),
                    Text(p.jam,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors
                                .chocolateMuted)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving'),
                          mode: LaunchMode
                              .externalApplication,
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.chocolate,
                          side: BorderSide(
                              color: const Color(
                                      0xFFDEC0B7)
                                  .withValues(
                                      alpha: 0.5)),
                          shape:
                              const StadiumBorder(),
                        ),
                        icon: const Icon(
                            Icons.navigation_outlined,
                            size: 16),
                        label: const Text(
                            'Rute di Google Maps',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              )),
          const Text(
            'Toko buka setiap hari kecuali ada keterangan jam operasional saat hari libur tiba.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.chocolateMuted),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(Recipe r) {
    final e = widget.repo.estCost(r);
    final bd = widget.repo.priceBreakdown(r).take(3).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 176,
                  width: double.infinity,
                  child: AppImage(
                      url: photoFor(r),
                      fallbackLetter: r.title),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: Text(
                    e.complete
                        ? '±${Money.rp((e.min + e.max) ~/ 2)} • estimasi'
                        : 'estimasi sebagian',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      widget.repo.isFavorite(r.docId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                    onPressed: () => widget.repo
                        .toggleFavorite(r.docId),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: AppColors.chocolate),
                          const SizedBox(width: 4),
                          Text(r.displayDuration,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color:
                                      AppColors.chocolate)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFFDCC6),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Text(r.displayDifficulty,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF311400))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(r.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.chocolate)),
          if (r.description.isNotEmpty)
            Text(r.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.chocolateMuted)),
          if (bd.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFDEC0B7)
                        .withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('RINCIAN BAHAN POKOK',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.275,
                              color: AppColors
                                  .chocolateMuted)),
                      const Spacer(),
                      Text('${bd.length} Bahan Utama',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...bd.map((b) => Container(
                        margin:
                            const EdgeInsets.only(bottom: 6),
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius:
                              BorderRadius.circular(48),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration:
                                  const BoxDecoration(
                                color:
                                    AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(b.key,
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12))),
                            Text(Money.rp(b.value),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                  'Porsi: ${r.servings ?? '-'}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chocolateMuted)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailScreen(
                          repo: widget.repo,
                          recipe: r)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF7F2500),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                child:
                    const Text('Lihat Langkah Masak →'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _change() {
    final c = TextEditingController(text: '$_budget');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Budget (Rp)'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              hintText: 'cth: 25000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(c.text
                      .replaceAll(RegExp(r'[^0-9]'), '')) ??
                  _budget;
              setState(() => _budget = v);
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }
}
