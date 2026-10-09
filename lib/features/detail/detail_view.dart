import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/nutrition_card.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../cooking/cooking_view.dart';
import 'detail_provider.dart';

/// Detail ala Stitch: hero foto + caption + judul + pil waktu/sulit
/// + kartu gizi + bahan berstatus + tips koki + CTA nempel bawah.
class DetailScreen extends StatefulWidget {
  final RecipeRepository repo;
  final Recipe recipe;
  const DetailScreen(
      {super.key, required this.repo, required this.recipe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailProvider _dp;

  static const _tips = [
    'Jangan masak dengan api terlalu besar agar bumbu meresap dan tidak gosong.',
    'Cicipi dan koreksi rasa di akhir — garam dulu sedikit, tambah bila kurang.',
    'Diamkan masakan 5 menit sebelum disajikan agar rasa lebih menyatu.',
    'Siapkan semua bahan (mise en place) sebelum menyalakan kompor.',
  ];

  @override
  void initState() {
    super.initState();
    _dp = DetailProvider();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.chocolate),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: AnimatedBuilder(
                    animation: widget.repo,
                    builder: (_, _) => IconButton(
                      icon: Icon(
                        widget.repo.isFavorite(r.docId)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: AppColors.primary,
                      ),
                      onPressed: () =>
                          widget.repo.toggleFavorite(r.docId),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                      url: photoFor(r),
                      fallbackLetter: r.title),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${r.category} • ${r.tags.take(3).join(' • ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _dp,
                  builder: (_, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.chocolate)),
                      const SizedBox(height: 2),
                      Text(
                        r.description.isEmpty
                            ? r.category
                            : r.description,
                        style: const TextStyle(
                            color:
                                AppColors.chocolateMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _pill(Icons.timer_outlined, 'WAKTU',
                              r.displayDuration),
                          const SizedBox(width: 12),
                          _pill(Icons.bar_chart, 'KESULITAN',
                              r.displayDifficulty),
                        ],
                      ),
                      const SizedBox(height: 16),
                      NutritionCard(recipe: r),
                      const SizedBox(height: 20),
                      Text(
                        'Ingredient (${r.ingredientsRaw.length} bahan)',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate),
                      ),
                      const SizedBox(height: 8),
                      ...r.ingredientsRaw.asMap().entries.map(
                            (e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _dp.toggle(e.key),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: _dp.checked
                                                .contains(e.key)
                                            ? AppColors.primary
                                            : AppColors.sand,
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                      ),
                                      child: _dp.checked
                                              .contains(e.key)
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        decoration: _dp.checked
                                                .contains(e.key)
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.sand,
                                      borderRadius:
                                          BorderRadius.circular(
                                              9999),
                                    ),
                                    child: Text(
                                      Recipe.prepStatus(
                                          e.value),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: AppColors
                                              .chocolateMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.soup_kitchen,
                                color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('Tips Koki',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tips[r.docId.hashCode.abs() %
                                        _tips.length],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors
                                            .chocolateMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.9),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D3D2314),
                blurRadius: 20,
                offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CookingScreen(
                      repo: widget.repo, recipe: r),
                ),
              ),
              icon:
                  const Icon(Icons.play_circle_outline),
              label: const Text('Mulai Memasak'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.chocolateMuted)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dp.dispose();
    super.dispose();
  }
}
