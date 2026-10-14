import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/recipe_repository.dart';
import '../budget/budget_view.dart';
import '../encyclopedia/encyclopedia_view.dart';
import '../places/places_view.dart';
import '../recipe_form/add_recipe_view.dart';
import '../search/results_view.dart';
import 'home_provider.dart';

/// Home v2 — ikut Figma "3. Home - MasakYuk v2" (62:1775):
/// header terracotta (salam + cari nama + cari bahan),
/// kategori, budget hemat, featured carousel, grid, ensiklopedia, tempat.
/// Foto & teks judul tetap dari data (dinamis), bukan tempelan mockup.
class HomeScreen extends StatefulWidget {
  final RecipeRepository repo;
  const HomeScreen({super.key, required this.repo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider _hp;
  final _titleCtrl = TextEditingController();
  final _budgetCtrl =
      TextEditingController(text: '25000');

  @override
  void initState() {
    super.initState();
    _hp = HomeProvider(widget.repo);
  }

  void _openResults({
    String title = 'Pencarian Bahan',
    Set<String>? inputs,
    String? chip,
    bool showAll = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ResultsScreen(
                repo: widget.repo,
                title: title,
                inputs: inputs,
                chip: chip,
                showAll: showAll,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddRecipeScreen(repo: widget.repo)),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_hp, widget.repo]),
        builder: (_, _) {
          if (!widget.repo.loaded) {
            return const Center(
                child: CircularProgressIndicator());
          }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(),
            _categoryRow(),
            _budgetCard(),
            _knowSection(),
            _placesSection(),
            const SizedBox(height: 24),
          ],
        );
        },
      ),
    );
  }

  /// Blok terracotta atas: salam + cari nama + cari bahan. (Figma: rounded-b-40)
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
          const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Halo Sobat MasakYuk',
                        style: TextStyle(
                            color: Color(0xFFFFC9B7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3)),
                    Text(
                      'Good Morning, ${widget.repo.userName.split(' ').first}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.65,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.3),
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
                    right: -2,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary,
                            width: 2),
                      ),
                      child: const Icon(Icons.star,
                          size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _nameSearch(),
          const SizedBox(height: 12),
          _bahanCard(),
        ],
      ),
    );
  }

  Widget _nameSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F3D2314),
              blurRadius: 8,
              offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _titleCtrl,
        onChanged: _hp.setTitle,
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          _openResultsByTitle(v.trim());
        },
        decoration: InputDecoration(
          hintText: 'Cari nama resep masakan...',
          hintStyle: TextStyle(
              fontSize: 12,
              color: AppColors.chocolateMuted
                  .withValues(alpha: 0.7)),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 17, vertical: 16),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.chocolateMuted),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(7),
            child: CircleAvatar(
              backgroundColor:
                  const Color(0xFF7F2500),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 20),
                onPressed: () {
                  final v = _titleCtrl.text.trim();
                  if (v.isEmpty) return;
                  _openResultsByTitle(v);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openResultsByTitle(String v) {
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

  Widget _bahanCard() {
    final n = _hp.inputs.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 17, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.kitchen_outlined,
                  size: 15, color: Colors.white),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Cari Berdasarkan Bahan di Kulkas',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: -0.3,
                      color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.6),
                  borderRadius:
                      BorderRadius.circular(9999),
                ),
                child: const Text('Pilih bahanmu',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFFC9B7))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                HomeProvider.bahanChips.map((b) {
              final sel = _hp.picked.contains(b);
              final label =
                  b[0].toUpperCase() + b.substring(1);
              return GestureDetector(
                onTap: () => _hp.togglePick(b),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel
                        ? Colors.white
                        : Colors.white
                            .withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          sel
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          size: 12,
                          color: sel
                              ? const Color(0xFF7F2500)
                              : Colors.white),
                      const SizedBox(width: 4),
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: sel
                                  ? const Color(0xFF7F2500)
                                  : Colors.white)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: n == 0
                  ? null
                  : () =>
                      _openResults(inputs: _hp.inputs),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    const Color(0xFF7F2500),
                minimumSize:
                    const Size.fromHeight(40),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
              child: Text(n == 0
                  ? 'Pilih bahan dulu'
                  : 'Cari dari $n bahan terpilih'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFDEC0B7)
                  .withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Masak Hemat Hari Ini',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDCC6),
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: const Text('± estimasi pasar',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF311400))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tentukan dana belanja dapur, kami pilihkan menu lezat ramah kantong.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.chocolateMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color:
                              AppColors.chocolateMuted),
                      hintText: '25.000',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(9999),
                        borderSide: BorderSide(
                            color: const Color(0xFFDEC0B7)
                                .withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _goBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.secondary,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.tune,
                        size: 16),
                    label: const Text('Cari Resep',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600)),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('KATEGORI PILIHAN',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: AppColors.chocolateMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () => _openResults(
                    title: 'Semua Resep',
                    showAll: true),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Geser',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7F2500))),
                    Icon(Icons.chevron_right,
                        size: 14,
                        color: Color(0xFF7F2500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HomeProvider.chips.map((c) {
                final sel = _hp.chip == c;
                return Padding(
                  padding:
                      const EdgeInsets.only(right: 8),
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
                    onSelected: (_) {
                      _hp.setChip(c);
                      if (c != 'Semua') {
                        _openResults(
                            title: c, chip: c);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _knowSection() {
    final items = widget.repo.encyclopedia.take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
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
                            color:
                                AppColors.primaryContainer,
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

  Widget _placesSection() {
    final items = widget.repo.places.take(2).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          ...items.map((p) => Card(
                margin:
                    const EdgeInsets.only(bottom: 10),
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
                      style:
                          const TextStyle(fontSize: 12)),
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _budgetCtrl.dispose();
    _hp.dispose();
    super.dispose();
  }
}
