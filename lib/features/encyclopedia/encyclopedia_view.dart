import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/money.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../places/place_detail_view.dart';
import 'article_view.dart';

/// Kamus Kuliner: search + tab Bahan/Resep/Tempat + grid.
/// Bahan: assets/encyclopedia.json. Resep & Tempat: data repo (dinamis).
class EncyclopediaScreen extends StatefulWidget {
  final RecipeRepository repo;
  const EncyclopediaScreen({super.key, required this.repo});

  @override
  State<EncyclopediaScreen> createState() =>
      _EncyclopediaScreenState();
}

class _EncyclopediaScreenState
    extends State<EncyclopediaScreen> {
  String _q = '';
  String _kat = 'Semua';
  String _tab = 'Bahan';
  final _ctrl = TextEditingController();

  String? _priceOf(Recipe r) {
    final e = widget.repo.estCost(r);
    if (!e.complete) return null;
    return '${Money.range(e.min, e.max)} • estimasi';
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    final nBahan = repo.encyclopedia.length;
    final allRes = repo.search({});
    final nResep = allRes.top3.length + allRes.rest.length;
    final nTempat = repo.places.length;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            bottom: false,
            child: Container(
            padding: const EdgeInsets.fromLTRB(
                20, 16, 20, 24),
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
                              .withValues(alpha: 0.1),
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
                    const Expanded(
                      child: Column(
                        children: [
                          Text('Ensiklopedia Kuliner',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: Colors.white)),
                          Text(
                              'Kamus Dapur Nusantara',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                  letterSpacing: 0.275,
                                  color:
                                      Color(0xFFFFC9B7))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(
                      () => _q = v.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: _tab == 'Bahan'
                        ? 'Cari bahan atau rempah dapur...'
                        : _tab == 'Resep'
                            ? 'Cari resep nusantara...'
                            : 'Cari tempat makan & belanja...',
                    hintStyle:
                        const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search,
                        color:
                            AppColors.chocolateMuted),
                  ),
                ),
              ],
            ),
          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 16, 20, 24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius:
                  BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                _segTab('Bahan', nBahan),
                const SizedBox(width: 4),
                _segTab('Resep', nResep),
                const SizedBox(width: 4),
                _segTab('Tempat', nTempat),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_tab == 'Bahan') ..._bahanTab()
          else if (_tab == 'Resep') ..._resepTab()
          else ..._tempatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segTab(String label, int count) {
    final active = _tab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = label),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(9999),
          ),
          child: Text('$label ($count)',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: active
                    ? Colors.white
                    : AppColors.chocolate,
              )),
        ),
      ),
    );
  }

  // ---------------- TAB BAHAN ----------------

  List<Widget> _bahanTab() {
    final repo = widget.repo;
    final kats = [
      'Semua',
      ...{for (final e in repo.encyclopedia) e.kat}
    ];
    final items = repo.encyclopedia.where((e) {
      final okQ = _q.isEmpty ||
          e.nama.toLowerCase().contains(_q) ||
          e.desc.toLowerCase().contains(_q);
      final okK = _kat == 'Semua' || e.kat == _kat;
      return okQ && okK;
    }).toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kats.map((k) {
            final sel = _kat == k;
            return Padding(
              padding:
                  const EdgeInsets.only(right: 8),
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
      const SizedBox(height: 16),
      _sectionTitle(
          'Bahan Dapur Populer', '(${items.length} Bahan)'),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ArticleScreen(
                      repo: widget.repo, info: e)),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sand,
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
                  Stack(
                    children: [
                      Container(
                        height: 104,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFEAE0),
                          borderRadius:
                              BorderRadius.circular(
                                  18),
                        ),
                        child: Center(
                          child: Text(
                            e.nama.isEmpty
                                ? '?'
                                : e.nama[0],
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight:
                                    FontWeight.w800,
                                color: Color(
                                    0xFFDEC0B7)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.secondary,
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: Text(e.kat,
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  letterSpacing: 0.25,
                                  fontWeight:
                                      FontWeight.w400)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(e.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.chocolate)),
                  Text('Asal: ${e.asal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors
                              .chocolateMuted)),
                  const SizedBox(height: 4),
                  Text(e.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF57423B))),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.only(top: 6),
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
                        Text('Pelajari',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppColors.primary)),
                        Spacer(),
                        Icon(Icons.arrow_forward,
                            size: 14,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE2D5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFFDEC0B7)
                  .withValues(alpha: 0.5)),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.menu_book_outlined,
                  size: 18, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('Rahasia Dapur Warisan',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate)),
                  SizedBox(height: 2),
                  Text(
                      'Bumbu segar yang diulek dadakan memberi aroma lebih kuat dibanding bumbu instan.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.chocolate)),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ---------------- TAB RESEP ----------------

  List<Widget> _resepTab() {
    final repo = widget.repo;
    final items =
        [...repo.search({}).top3, ...repo.search({}).rest]
            .where((r) {
      if (_q.isEmpty) return true;
      return r.title.toLowerCase().contains(_q) ||
          r.description.toLowerCase().contains(_q) ||
          r.category.toLowerCase().contains(_q);
    }).toList();
    return [
      _sectionTitle(
          'Resep Nusantara', '(${items.length} Resep)'),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('Tidak ada resep yang cocok.',
                style: TextStyle(
                    color:
                        AppColors.chocolateMuted)),
          ),
        )
      else
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => RecipeCard(
            recipe: items[i],
            imageHeight: 110,
            titleSize: 14,
            priceLabel: _priceOf(items[i]),
            favorite:
                repo.isFavorite(items[i].docId),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DetailScreen(
                      repo: repo,
                      recipe: items[i])),
            ),
            onFavorite: () =>
                repo.toggleFavorite(items[i].docId),
          ),
        ),
    ];
  }

  // ---------------- TAB TEMPAT ----------------

  List<Widget> _tempatTab() {
    final repo = widget.repo;
    final items = repo.places.where((p) {
      if (_q.isEmpty) return true;
      return p.nama.toLowerCase().contains(_q) ||
          p.jenis.toLowerCase().contains(_q) ||
          p.alamat.toLowerCase().contains(_q);
    }).toList();
    return [
      _sectionTitle(
          'Tempat Kuliner', '(${items.length} Tempat)'),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('Tidak ada tempat yang cocok.',
                style: TextStyle(
                    color:
                        AppColors.chocolateMuted)),
          ),
        )
      else
        ...items.map((p) => Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFDEC0B7)
                        .withValues(alpha: 0.3)),
              ),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PlaceDetailScreen(
                              place: p)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration:
                          const BoxDecoration(
                        color: Color(0xFFFFEAE0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.nama.isEmpty
                              ? '?'
                              : p.nama[0],
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.w800,
                              color: Color(
                                  0xFFDEC0B7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(p.nama,
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: AppColors
                                      .chocolate)),
                          const SizedBox(height: 2),
                          Text(
                              '${p.jenis} • ★ ${p.rating} (${p.ulasan})',
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors
                                      .chocolateMuted)),
                          Text(p.alamat,
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors
                                      .chocolateMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.primary),
                  ],
                ),
              ),
            )),
    ];
  }

  Widget _sectionTitle(String title, String count) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.chocolate)),
        const SizedBox(width: 8),
        Text(count,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.chocolateMuted)),
        const Spacer(),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_by_alpha,
                size: 14,
                color: AppColors.secondary),
            SizedBox(width: 4),
            Text('A-Z',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.secondary)),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
