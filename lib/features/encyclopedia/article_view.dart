import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/recipe_repository.dart';
import '../../models/know.dart';
import '../detail/detail_view.dart';

/// Artikel bahan: hero + deskripsi + fakta + aksi resep & Wikipedia.
class ArticleScreen extends StatelessWidget {
  final RecipeRepository repo;
  final IngredientInfo info;
  const ArticleScreen(
      {super.key, required this.repo, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(info.nama)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            color: AppColors.primaryContainer,
            child: Center(
              child: Text(
                info.nama.isEmpty ? '?' : info.nama[0],
                style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(info.kat)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Asal: ${info.asal}',
                          style: const TextStyle(
                              color: AppColors
                                  .chocolateMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(info.nama,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.chocolate)),
                const SizedBox(height: 8),
                Text(info.desc,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6)),
                const SizedBox(height: 14),
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
                      const Icon(Icons.lightbulb_outline,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Tahukah kamu?',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700)),
                            Text(info.fakta,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors
                                        .chocolateMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openRecipes(context),
                    icon: const Icon(
                        Icons.restaurant_menu,
                        size: 18),
                    label: const Text(
                        'Lihat resep dengan bahan ini'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                        Uri.parse(info.wiki),
                        mode: LaunchMode
                            .externalApplication),
                    icon: const Icon(Icons.open_in_new,
                        size: 18),
                    label: const Text(
                        'Baca di Wikipedia'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRecipes(BuildContext context) {
    final key = info.nama.toLowerCase().split(' ').first;
    final hits = repo.searchTitle(info.nama);
    final hits2 = repo.search({key});
    final all = [...hits, ...hits2.top3, ...hits2.rest];
    final seen = <String>{};
    final uniq =
        all.where((r) => seen.add(r.docId)).toList();
    if (uniq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Belum ada resep dengan bahan ini — tambah sendiri yuk!')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DetailScreen(
              repo: repo, recipe: uniq.first)),
    );
  }
}
