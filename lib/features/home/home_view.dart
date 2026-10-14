import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/food_photos.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../budget/budget_view.dart';
import '../detail/detail_view.dart';
import '../encyclopedia/encyclopedia_view.dart';
import '../places/places_view.dart';
import 'home_provider.dart';

/// Home v2: header + search nama + checklist bahan + budget +
/// kategori + featured + grid + Kenali Bahan + Makan Sekitar.
class HomeScreen extends StatefulWidget {
  final RecipeRepository repo;
  const HomeScreen({super.key, required this.repo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider _hp;
  final _ctrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _budgetCtrl =
      TextEditingController(text: '25000');

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
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _curvedHeader(),
            _nameSearch(),
            _bahanPicker(),
            _budgetCard(),
            if (!_hp.searching) ...[
              _categoryRow(),
              _featuredSection(),
              _gridSection(),
              _knowSection(),
              _placesSection(),
            ] else
              _resultSection(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

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

  /// Search 1: nama resep.
  Widget _nameSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
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
          controller: _titleCtrl,
          onChanged: _hp.setTitle,
          decoration: InputDecoration(
            hintText: 'Cari nama resep masakan...',
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
                      _hp.setTitle(_titleCtrl.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Search 2: checklist bahan tap-to-toggle.
  Widget _bahanPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cari Berdasarkan Bahan di Kulkas',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                Text('${_hp.picked.length} dipilih',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HomeProvider.bahanChips.map((b) {
                final sel = _hp.picked.contains(b);
                return ChoiceChip(
                  label: Text(b),
                  selected: sel,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                      color: sel
                          ? Colors.white
                          : AppColors.chocolate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  shape: const StadiumBorder(),
                  onSelected: (_) => _hp.togglePick(b),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              onChanged: _hp.setQuery,
              decoration: const InputDecoration(
                hintText: '...atau ketik bahan lain',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.edit,
                    size: 18,
                    color: AppColors.chocolateMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu budget hemat.
  Widget _budgetCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.savings_outlined,
                    color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Masak Hemat Hari Ini',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
                Chip(label: Text('± estimasi pasar')),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tentukan dana belanja dapur, kami pilihkan menu lezat ramah kantong.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.chocolateMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Rp 25.000', filled: true,
                  fillColor: Colors.white),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _goBudget,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Cari Resep'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBudget() {
    final v = int.tryParse(
            _budgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        25000;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BudgetScreen(
              repo: widget.repo, budget: v)),
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

  /// Section ensiklopedia → layar indeks.
  Widget _knowSection() {
    final items = widget.repo.encyclopedia.take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kenali Bahan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text('Ensiklopedi bumbu & rahasia dapur nusantara',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.chocolateMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EncyclopediaScreen(
                          repo: widget.repo)),
                ),
                child: const Text('Semua ›'),
              ),
            ],
          ),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final e = items[i];
                return SizedBox(
                  width: 150,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EncyclopediaScreen(
                                    repo: widget.repo)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 90,
                            color: AppColors.primaryContainer,
                            child: Center(
                              child: Text(
                                e.nama.isEmpty
                                    ? '?'
                                    : e.nama[0],
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: Colors.white70),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(e.nama,
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 13)),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            EncyclopediaScreen(
                                                repo: widget
                                                    .repo)),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize:
                                        const Size(0, 28),
                                  ),
                                  child: const Text(
                                      'Pelajari Selengkapnya ›',
                                      style: TextStyle(
                                          fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Section tempat → layar peta.
  Widget _placesSection() {
    final items = widget.repo.places.take(2).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Makan & Belanja di Sekitar',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text('Pasar basah & toko bahan segar terdekat',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.chocolateMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlacesScreen(
                          repo: widget.repo)),
                ),
                child: const Text('Lihat ›'),
              ),
            ],
          ),
          ...items.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.sand,
                    child: Icon(Icons.store,
                        color: AppColors.primary),
                  ),
                  title: Text(p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: Text(p.jenis,
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlacesScreen(
                            repo: widget.repo)),
                  ),
                ),
              )),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PlacesScreen(repo: widget.repo)),
              ),
              icon: const Icon(Icons.explore_outlined,
                  size: 18),
              label: const Text(
                  'Jelajahi Tempat Belanja di Sekitar'),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Tidak ketemu — coba kata lain atau tambah resep sendiri.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.chocolateMuted),
              ),
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
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
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
