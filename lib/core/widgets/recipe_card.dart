import 'package:flutter/material.dart';
import '../../data/recipe_photo.dart';
import '../../models/recipe.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';

/// Kartu resep ala Figma Home v2: foto rounded + ribbon harga + hati
/// + judul + deskripsi + divider + durasi & badge kesulitan.
/// Foto tetap dinamis dari data (pool + fallback monogram).
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final int? matchCount;
  final String? matchLabel;
  final String? priceLabel;
  final double imageHeight;
  final double titleSize;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    this.matchCount,
    this.matchLabel,
    this.priceLabel,
    this.imageHeight = 118,
    this.titleSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: AppImage(
                        url: photoFor(recipe),
                        fallbackLetter: recipe.title,
                      ),
                    ),
                  ),
                  if (priceLabel != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(9999),
                        ),
                        child: Text(
                          priceLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: Icon(
                          favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.primary,
                        ),
                        onPressed: onFavorite,
                      ),
                    ),
                  ),
                  if (matchCount != null && matchCount! > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                              Radius.circular(9999)),
                        ),
                        child: Text(
                          matchLabel ??
                              '$matchCount cocok',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                        color: AppColors.chocolate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.description.isEmpty
                          ? recipe.category
                          : recipe.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.chocolateMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 9),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFFDEC0B7)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14,
                              color: AppColors.chocolateMuted),
                          const SizedBox(width: 4),
                          Text(
                            recipe.displayDuration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.chocolateMuted,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDCC6),
                              borderRadius:
                                  BorderRadius.circular(9999),
                            ),
                            child: Text(
                              recipe.displayDifficulty,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF822701)),
                            ),
                          ),
                        ],
                      ),
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
}
