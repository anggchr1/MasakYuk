import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/recipe_card.dart';
import '../notifications/notifications_view.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../recipe_form/add_recipe_view.dart';

/// Favorit ala Stitch: header terracotta + tab + sortir + grid + FAB.
class FavoritesScreen extends StatefulWidget {
  final RecipeRepository repo;
  const FavoritesScreen({super.key, required this.repo});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _mine = false;
  bool _searching = false;
  String _sort = 'Terbaru';
  final _ctrl = TextEditingController();
  static const _sorts = [
    'Terbaru',
    'Nama A-Z',
    'Waktu Tersingkat',
    'Populer'
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        var items = _mine
            ? widget.repo.customs
                .where((r) => r.ownerId == 'local')
                .toList()
            : widget.repo.favorites;
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
          case 'Populer':
            items.sort((a, b) => b.loves.compareTo(a.loves));
          default:
            items = items.reversed.toList();
        }
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(items),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 10, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Koleksi Pilihan',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _sort,
                      underline: const SizedBox(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                      items: _sorts
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('Urutkan: $s')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _sort = v!),
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Belum ada di sini',
                  desc:
                      'Ketuk hati di resep atau tulis resep sendiri.',
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
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
                            favorite: widget.repo
                                .isFavorite(r.docId),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                      repo: widget.repo,
                                      recipe: r)),
                            ),
                            onFavorite: () => widget.repo
                                .toggleFavorite(r.docId),
                          ),
                          if (r.origin == 'custom' &&
                              !r.isPublished)
                            const Positioned(
                              left: 8,
                              top: 8,
                              child: Chip(label: Text('Draf')),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              _inspiration(),
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
            icon: const Icon(Icons.add),
            label: const Text('Tambah Resep'),
          ),
        );
      },
    );
  }

  Widget _header(List<Recipe> items) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
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
                    Text('Koleksi Resep',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    Text('Resep tersimpan siap dimasak',
                        style:
                            TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white
                        .withValues(alpha: 0.2),
                    child: IconButton(
                      icon: const Icon(
                          Icons.notifications_outlined),
                      color: Colors.white,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                NotificationsScreen(
                                    repo: widget.repo)),
                      ),
                    ),
                  ),
                  if (widget.repo.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.amber,
                        child: Text(
                          '${widget.repo.unreadCount}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor:
                    Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  icon: Icon(_searching
                      ? Icons.close
                      : Icons.search),
                  color: Colors.white,
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    _ctrl.clear();
                  }),
                ),
              ),
            ],
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari di koleksimu...',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: false,
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white70),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                _tab('Resep Favorit', !_mine,
                    () => setState(() => _mine = false)),
                _tab('Resep Pribadi Saya', _mine,
                    () => setState(() => _mine = true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active
                  ? AppColors.primary
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inspiration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.lightbulb_outline,
                  color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inspirasi Masak Hari Ini',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                      'Simpan bumbu marinasi minimal 20 menit agar rasa lebih meresap.',
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              AppColors.chocolateMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
