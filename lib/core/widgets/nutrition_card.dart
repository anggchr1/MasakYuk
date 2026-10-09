import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../theme/app_theme.dart';

/// Kartu gizi 4 metrik + badge sumber (Dataset / Estimasi AI) + insight.
/// Aturan label jujur (PRD NFR-05): missing = tampil Estimasi AI.
class NutritionCard extends StatelessWidget {
  final Recipe recipe;
  const NutritionCard({super.key, required this.recipe});

  String _fmt(double? v, String unit) =>
      v == null ? '-' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}$unit';

  @override
  Widget build(BuildContext context) {
    final fromDataset = recipe.hasNutrition;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Informasi Gizi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.chocolate,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: fromDataset
                        ? AppColors.primary
                        : AppColors.amber,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    fromDataset ? 'Dataset' : 'Estimasi AI (Gemini)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric(_fmt(recipe.calories, ''), 'kkal', 'Kalori'),
                _metric(_fmt(recipe.proteins, 'g'), 'gram', 'Protein'),
                _metric(_fmt(recipe.fat, 'g'), 'gram', 'Lemak'),
                _metric(
                    _fmt(recipe.carbohydrate, 'g'), 'gram', 'Karbo'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                fromDataset
                    ? _insight()
                    : 'Belum ada data gizi — buka dengan internet untuk estimasi AI (M3).',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.chocolate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String unit, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.chocolate)),
        Text(unit,
            style: const TextStyle(
                fontSize: 11, color: AppColors.chocolateMuted)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ],
    );
  }

  String _insight() {
    final p = recipe.proteins ?? 0;
    final f = recipe.fat ?? 0;
    final c = recipe.calories ?? 0;
    if (p >= 15 && f <= 12) {
      return 'Tinggi protein & rendah lemak, cocok untuk menu diet sehat!';
    }
    if (c >= 400) {
      return 'Kalori padat — pas buat anak kos yang butuh tenaga, kurang cocok untuk diet ketat.';
    }
    return 'Komposisi seimbang untuk makan harian keluarga.';
  }
}
