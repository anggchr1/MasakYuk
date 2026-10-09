import 'package:flutter/material.dart';
import '../../data/recipe_photo.dart';
import '../../models/recipe.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';

/// Kartu resep ala Stitch: foto penuh atas + hati + nama + deskripsi
/// + badge durasi & kesulitan. Foto = pool Stitch + fallback monogram.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final int? matchCount;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    this.matchCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: AppImage(
                    url: photoFor(recipe),
                    fallbackLetter: recipe.title,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14,
                          color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        recipe.displayDuration,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius:
                              BorderRadius.circular(9999),
                        ),
                        child: Text(
                          recipe.displayDifficulty,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
