import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';

/// Hasil budget: header editable + sortir + rincian harga + tempat.
/// Range ±25%: budget 20k → 15–25k. Tak lengkap = label + di belakang.
class BudgetScreen extends StatefulWidget {
  final RecipeRepository repo;
  final int budget;
  const BudgetScreen(
      {super.key, required this.repo, required this.budget});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late int _budget;
  String _sort = 'Termurah';
  static const _sorts = ['Termurah', 'Paling Cepat', 'Populer'];

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        if (!widget.repo.loaded) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()));
        }
        var items = widget.repo.budgetSearch(_budget);
        switch (_sort) {
          case 'Paling Cepat':
            items.sort((a, b) => a.stepsList.length
                .compareTo(b.stepsList.length));
            break;
          case 'Populer':
            items.sort(
                (a, b) => b.loves.compareTo(a.loves));
            break;
          default:
            break; // repo sudah urut termurah
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Budget Maksimal'),
            actions: [
              TextButton(
                onPressed: _change,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white),
                child: const Text('Ubah'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Money.rp(_budget),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const Text(
                        'Target belanja harian keluarga',
                        style: TextStyle(
                            color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('URUTKAN RESEP',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              AppColors.chocolateMuted)),
                  const Spacer(),
                  Text('${items.length} Menu Ditemukan',
                      style: const TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.chocolateMuted)),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sorts.map((s) {
                    final sel = _sort == s;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
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
              const SizedBox(height: 10),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Semua biaya berdasarkan harga pasar tradisional & warung. Nilai bertanda estimasi dihitung per porsi masak harian.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chocolateMuted),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Tidak ada menu dalam budget ini.\nNaikkan budget atau tambah resep sendiri.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.chocolateMuted),
                  ),
                ),
              ...items.map((r) => _budgetCard(r)),
            ],
          ),
        );
      },
    );
  }

  Widget _budgetCard(Recipe r) {
    final e = widget.repo.estCost(r);
    final bd = widget.repo.priceBreakdown(r).take(3).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: AppImage(
                    url: photoFor(r),
                    fallbackLetter: r.title),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: Text(
                    e.complete
                        ? '±${Money.rp((e.min + e.max) ~/ 2)} • estimasi'
                        : 'estimasi sebagian',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
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
                      widget.repo.isFavorite(r.docId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.primary,
                    ),
                    onPressed: () => widget.repo
                        .toggleFavorite(r.docId),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.chocolate)),
                if (bd.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('RINCIAN BAHAN POKOK',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color:
                              AppColors.chocolateMuted)),
                  const SizedBox(height: 4),
                  ...bd.map((b) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2),
                        child: Row(
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color:
                                        AppColors.primary)),
                            Expanded(
                                child: Text(b.key,
                                    style: const TextStyle(
                                        fontSize: 13))),
                            Text(Money.rp(b.value),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700)),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(
                              repo: widget.repo,
                              recipe: r)),
                    ),
                    child:
                        const Text('Lihat Langkah Masak →'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _change() {
    final c = TextEditingController(text: '$_budget');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Budget (Rp)'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              hintText: 'cth: 25000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(c.text
                      .replaceAll(RegExp(r'[^0-9]'), '')) ??
                  _budget;
              setState(() => _budget = v);
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }
}
