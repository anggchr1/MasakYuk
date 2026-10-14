import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/money.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../notifications/notifications_view.dart';
import '../recipe_form/add_recipe_view.dart';

/// Favorit Figma: header + search + tab hitung + sort chips +
/// mode Kelola (hapus cepat) + tips + Buat Resep Baru.
class FavoritesScreen extends StatefulWidget {
  final RecipeRepository repo;
  const FavoritesScreen({super.key, required this.repo});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _mine = false;
  bool _manage = false;
  String _sort = 'Terbaru Disimpan';
  final _ctrl = TextEditingController();
  static const _sorts = [
    'Terbaru Disimpan',
    'Waktu Tersingkat',
    'Nama A-Z',
    'Paling Populer'
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        final favs = widget.repo.favorites;
        final mine = widget.repo.customs
            .where((r) => r.ownerId == 'local')
            .toList();
        var items = _mine ? mine : favs;
        final q = _ctrl.text.toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((r) => r.title.toLowerCase().contains(q))
              .toList();
        }
        switch (_sort) {
          case 'Nama A-Z':
            items.sort((a, b) => a.title.compareTo(b.title));
          case 'Waktu Tersingkat':
            items.sort((a, b) => a.stepsList.length
                .compareTo(b.stepsList.length));
          case 'Paling Populer':
            items.sort((a, b) => b.loves.compareTo(a.loves));
          default:
            items = items.reversed.toList();
        }
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(),
              _tabs(favs.length, mine.length),
              _sortRow(items.length),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.favorite_border,
                  title: _mine
                      ? 'Belum ada resep buatanmu'
                      : 'Belum ada favorit',
                  desc:
                      'Ketuk hati di resep atau tulis resep sendiri.',
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 12, 20, 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final r = items[i];
                        return Stack(
                          children: [
                            RecipeCard(
                              recipe: r,
                              imageHeight: 144,
                              titleSize: 18,
                              favorite: widget.repo
                                  .isFavorite(r.docId),
                              priceLabel: _priceOf(r),
                            onTap: () => _manage
                                ? null
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(
                                                repo: widget
                                                    .repo,
                                                recipe:
                                                    r)),
                                  ),
                            onFavorite: () => widget.repo
                                .toggleFavorite(r.docId),
                          ),
                          if (r.origin == 'custom' &&
                              !r.isPublished)
                            const Positioned(
                              left: 8,
                              top: 8,
                              child: Chip(
                                  label:
                                      Text('Draf')),
                            ),
                          if (_manage)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.error,
                                child: IconButton(
                                  padding:
                                      EdgeInsets.zero,
                                  iconSize: 16,
                                  icon: const Icon(
                                      Icons.close,
                                      color:
                                          Colors.white),
                                  onPressed: () =>
                                      _remove(r),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              _tips(),
              const SizedBox(height: 90),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AddRecipeScreen(repo: widget.repo)),
            ),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('Buat Resep Baru'),
          ),
        );
      },
    );
  }

  String? _priceOf(Recipe r) {
    final e = widget.repo.estCost(r);
    if (!e.complete) return null;
    return '${Money.range(e.min, e.max)} • estimasi';
  }

  Future<void> _remove(Recipe r) async {
    if (r.origin == 'custom') {
      final ok = await ConfirmDialog.ask(
        context,
        title: 'Hapus resep ini?',
        desc:
            '"${r.title}" akan dihapus permanen dari koleksimu.',
        yesLabel: 'Ya, Hapus',
      );
      if (ok) widget.repo.deleteCustom(r.docId);
    } else {
      widget.repo.toggleFavorite(r.docId);
    }
  }

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF7F2500),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dapur MasakMania',
                        style: TextStyle(
                            color: Color(0xFFFFB59C),
                            fontSize: 12,
                            letterSpacing: 0.3)),
                    Text('Koleksi Saya',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.65)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(
                              repo: widget.repo)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white),
                    ),
                    if (widget.repo.unreadCount > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    const Color(0xFF7F2500),
                                width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari dalam resep tersimpan...',
                hintStyle:
                    TextStyle(fontSize: 14),
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.chocolateMuted),
                suffixIcon: Icon(Icons.tune,
                    color: AppColors.chocolateMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(int favCount, int mineCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          children: [
            _tab(Icons.favorite, 'Resep Favorit', favCount,
                !_mine, () => setState(() => _mine = false)),
            const SizedBox(width: 6),
            _tab(Icons.menu_book, 'Resep Pribadi', mineCount,
                _mine, () => setState(() => _mine = true)),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int count,
      bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : AppColors.chocolate),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: active
                        ? Colors.white
                        : AppColors.chocolate,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF7F2500)
                          .withValues(alpha: 0.5)
                      : const Color(0xFFFFDBCA),
                  borderRadius:
                      BorderRadius.circular(9999),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: active
                          ? Colors.white
                          : AppColors.chocolateMuted,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortRow(int n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sorts.map((s) {
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
                    onSelected: (_) =>
                        setState(() => _sort = s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chocolateMuted),
                  children: [
                    const TextSpan(
                        text: 'Menampilkan '),
                    TextSpan(
                        text: '$n masakan',
                        style: const TextStyle(
                            color:
                                AppColors.chocolate)),
                    const TextSpan(
                        text: ' tersimpan'),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _manage = !_manage),
                icon: Icon(
                    _manage
                        ? Icons.check
                        : Icons.manage_accounts_outlined,
                    size: 14,
                    color: const Color(0xFF7F2500)),
                label: Text(_manage ? 'Selesai' : 'Kelola',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F2500))),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEAE0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0x1A7F2500),
              child: Icon(Icons.lightbulb_outline,
                  color: AppColors.primary),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('Tips Belanja MasakYuk',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w600)),
                  Text(
                    'Estimasi harga dihitung berdasarkan rata-rata pasar basah lokal mingguan.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .chocolateMuted),
                  ),
                ],
              ),
            ),
          ],
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
