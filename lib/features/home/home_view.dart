import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/food_photos.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import 'home_provider.dart';

/// Home ala Stitch: header lengkung + search jelas di bawahnya
/// + chip + Featured + grid. Ketuk tab Beranda 2x = reset filter.
class HomeScreen extends StatefulWidget {
  final RecipeRepository repo;
  const HomeScreen({super.key, required this.repo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider _hp;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hp = HomeProvider(widget.repo);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hp, widget.repo]),
      builder: (_, _) {
        if (!widget.repo.loaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final searching = _hp.inputs.isNotEmpty ||
            _hp.chip != 'Semua' ||
            _hp.showAll;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _curvedHeader(),
            _searchSection(),
            if (!searching) ...[
              _categoryRow(),
              _featuredSection(),
              _gridSection(),
            ] else
              _resultSection(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ---- Header lengkung terracotta (tanpa search menempel) ----
  Widget _curvedHeader() {
    return ClipPath(
      clipper: _HeaderClip(),
      child: Container(
        color: AppColors.primary,
        padding:
            const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Halo Sobat MasakYuk',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12)),
                  Text(
                    'Good Morning, ${widget.repo.userName.split(' ').first}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: AppImage(
                  url: FoodPhotos.avatar,
                  fallbackLetter: widget.repo.userName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Search sebagai fitur utama: label + bar besar di bawah header ----
  Widget _searchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cari Resep',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.chocolate)),
          const SizedBox(height: 2),
          const Text('Tulis bahan yang ada di kulkasmu',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.chocolateMuted)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A3D2314),
                    blurRadius: 24,
                    offset: Offset(0, 8)),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: _hp.setQuery,
              decoration: InputDecoration(
                hintText: 'Misal: telur, ayam, cabai...',
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.chocolateMuted),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                      onPressed: () =>
                          _hp.setQuery(_ctrl.text),
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

  Widget _categoryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const Row(
            children: [
              Text('KATEGORI PILIHAN',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.chocolateMuted)),
              Spacer(),
              Text('Geser →',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HomeProvider.chips.map((c) {
                final sel = _hp.chip == c;
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
                        fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                    onSelected: (_) => _hp.setChip(c),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredSection() {
    final res = widget.repo.search({});
    final feat = res.top3;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Text('Featured Recipe',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolate)),
              const Spacer(),
              TextButton(
                onPressed: _hp.revealAll,
                child: const Text('View All ›'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            itemCount: feat.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 210,
              child: RecipeCard(
                recipe: feat[i],
                favorite:
                    widget.repo.isFavorite(feat[i].docId),
                onTap: () => _open(feat[i]),
                onFavorite: () =>
                    widget.repo.toggleFavorite(feat[i].docId),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gridSection() {
    final res = widget.repo.search({});
    final items = [...res.top3, ...res.rest].take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resep Buat Kamu',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text(
                        'Inspirasi resep cepat olahan dapur hari ini',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.chocolateMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _hp.revealAll,
                child: const Text('View All ›'),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => RecipeCard(
              recipe: items[i],
              favorite:
                  widget.repo.isFavorite(items[i].docId),
              onTap: () => _open(items[i]),
              onFavorite: () =>
                  widget.repo.toggleFavorite(items[i].docId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultSection() {
    final res = _hp.results;
    final shown = [...res.top3, if (_hp.showAll) ...res.rest];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paling Cocok (${res.top3.length})',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.chocolate),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Tidak Ditemukan',
              desc:
                  'Bahan tidak tersedia atau hasil pencarian nihil. Coba kata lain atau tambah resep sendiri.',
            ),
          ...shown.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecipeCard(
                  recipe: r,
                  favorite: widget.repo.isFavorite(r.docId),
                  matchCount: _hp.inputs.isEmpty
                      ? null
                      : r.matchScore(_hp.inputs),
                  onTap: () => _open(r),
                  onFavorite: () =>
                      widget.repo.toggleFavorite(r.docId),
                ),
              )),
          if (!_hp.showAll && res.rest.isNotEmpty)
            OutlinedButton(
              onPressed: _hp.revealAll,
              child:
                  Text('Lihat ${res.rest.length} lainnya →'),
            ),
        ],
      ),
    );
  }

  void _open(Recipe r) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              DetailScreen(repo: widget.repo, recipe: r)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _hp.dispose();
    super.dispose();
  }
}

class _HeaderClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..lineTo(0, size.height - 32)
      ..quadraticBezierTo(size.width / 2, size.height + 16,
          size.width, size.height - 32)
      ..lineTo(size.width, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
