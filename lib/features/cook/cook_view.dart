import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/money.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../search/results_view.dart';

/// Tab Masak: halaman browse semua resep — search + kategori
/// (Sarapan, Seafood, ...) + carousel Featured + grid.
/// Pindahan dari Beranda agar Beranda ramping.
class CookScreen extends StatefulWidget {
  final RecipeRepository repo;
  const CookScreen({super.key, required this.repo});

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  String _chip = 'Semua';
  final _titleCtrl = TextEditingController();

  static const _chips = [
    'Semua',
    'Sarapan',
    'Cepat & Mudah',
    'Pedas',
    'Nusantara',
    'Ayam & Daging',
    'Seafood',
    'Sayuran',
  ];

  String? _priceOf(Recipe r) {
    final e = widget.repo.estCost(r);
    if (!e.complete) return null;
    return '±${Money.rp((e.min + e.max) ~/ 2)} • estimasi';
  }

  List<Recipe> get _items {
    if (_chip == 'Semua') {
      final res = widget.repo.search({});
      return [...res.top3, ...res.rest];
    }
    return widget.repo.byDisplayCategory(_chip);
  }

  void _openTitle(String v) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ResultsScreen(
                repo: widget.repo,
                title: 'Hasil: "$v"',
                initial: widget.repo.searchTitle(v),
                showAll: true,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        if (!widget.repo.loaded) {
          return const Center(
              child: CircularProgressIndicator());
        }
        final items = _items;
        final feat = items.take(3).toList();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(),
            const SizedBox(height: 20),
            _chipRow(),
            if (feat.isNotEmpty) ...[
              _sectionHead('Featured Recipe'),
              SizedBox(
                height: 300,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: feat.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 16),
                  itemBuilder: (_, i) => SizedBox(
                    width: 240,
                    child: RecipeCard(
                      recipe: feat[i],
                      imageHeight: 144,
                      titleSize: 18,
                      priceLabel:
                          _priceOf(feat[i]),
                      favorite: widget.repo
                          .isFavorite(feat[i].docId),
                      onTap: () => _open(feat[i]),
                      onFavorite: () => widget.repo
                          .toggleFavorite(
                              feat[i].docId),
                    ),
                  ),
                ),
              ),
            ],
            _sectionHead(
                _chip == 'Semua'
                    ? 'Resep Buat Kamu'
                    : 'Kategori: $_chip'),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 32),
                      child: Center(
                        child: Text(
                            'Belum ada resep di kategori ini.',
                            style: TextStyle(
                                color: AppColors
                                    .chocolateMuted)),
                      ),
                    )
                  : GridView.builder(
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
                      itemBuilder: (_, i) =>
                          RecipeCard(
                        recipe: items[i],
                        imageHeight: 120,
                        titleSize: 15,
                        priceLabel:
                            _priceOf(items[i]),
                        favorite: widget.repo
                            .isFavorite(
                                items[i].docId),
                        onTap: () =>
                            _open(items[i]),
                        onFavorite: () => widget.repo
                            .toggleFavorite(
                                items[i].docId),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mau Masak Apa?',
              style: TextStyle(
                  color: Color(0xFFFFC9B7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const Text('Jelajahi Resep',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.65)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(9999),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _titleCtrl,
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                _openTitle(v.trim());
              },
              decoration: InputDecoration(
                hintText: 'Cari nama resep masakan...',
                hintStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.chocolateMuted
                        .withValues(alpha: 0.7)),
                filled: false,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 17, vertical: 16),
                prefixIcon: const Icon(Icons.search,
                    color:
                        AppColors.chocolateMuted),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(7),
                  child: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF7F2500),
                    child: IconButton(
                      icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20),
                      onPressed: () {
                        final v =
                            _titleCtrl.text.trim();
                        if (v.isEmpty) return;
                        _openTitle(v);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _chips.map((c) {
          final sel = _chip == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                  c[0].toUpperCase() + c.substring(1)),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.sand,
              labelStyle: TextStyle(
                  color: sel
                      ? Colors.white
                      : AppColors.chocolate,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
              shape: const StadiumBorder(),
              onSelected: (_) =>
                  setState(() => _chip = c),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionHead(String title) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chocolate)),
        ],
      ),
    );
  }

  void _open(Recipe r) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DetailScreen(
              repo: widget.repo, recipe: r)),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
}
