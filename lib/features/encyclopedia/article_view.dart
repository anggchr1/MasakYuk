import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/recipe_repository.dart';
import '../../models/know.dart';
import '../detail/detail_view.dart';

/// Artikel bahan v2: hero + latin + info grid + artikel + harga +
/// fakta + pasangan + tombol resep. (Tanpa angka gizi.)
class ArticleScreen extends StatefulWidget {
  final RecipeRepository repo;
  final IngredientInfo info;
  const ArticleScreen(
      {super.key, required this.repo, required this.info});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final pairs = info.pairs.isEmpty
        ? defaultPairs(info.kat)
        : info.pairs;
    final repo = widget.repo;
    final key =
        info.nama.toLowerCase().split(' ').first;
    final nResep = repo.search({key}).top3.length +
        repo.search({key}).rest.length +
        repo.searchTitle(info.nama).length;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(
                height: 340,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      info.nama.isEmpty
                          ? '?'
                          : info.nama[0],
                      style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDEC0B7)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 16,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: const Icon(
                              Icons.arrow_back,
                              size: 18,
                              color:
                                  AppColors.chocolate),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger
                                .of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Bookmark bahan aktif di versi berikutnya.'))),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: const Icon(
                              Icons.bookmark_border,
                              size: 20,
                              color:
                                  AppColors.chocolate),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger
                                .of(context)
                            .showSnackBar(SnackBar(
                                content: Text(
                                    'Bagikan ${info.nama} — segera hadir.'))),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: const Icon(
                              Icons.share_outlined,
                              size: 20,
                              color:
                                  AppColors.chocolate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (info.latin.isNotEmpty)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.chocolate
                          .withValues(alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(9999),
                    ),
                    child: Text(info.latin,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: Text(info.kat,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text(info.nama,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.65,
                        color: Color(0xFF7F2500))),
                Text('Emas Alami Dapur Nusantara',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color:
                            AppColors.chocolateMuted)),
                const SizedBox(height: 12),
                _factPill(Icons.explore, 'ASAL USUL',
                    info.asal),
                const SizedBox(height: 8),
                _factPill(Icons.local_fire_department,
                    'KARAKTER',
                    info.karakter.isEmpty
                        ? _karakterDefault(
                            info.kat)
                        : info.karakter),
                const SizedBox(height: 8),
                _factPill(Icons.inventory_2,
                    'PENYIMPANAN DAPUR',
                    info.simpan.isEmpty
                        ? 'Suhu ruang kering (2–3 minggu)'
                        : info.simpan),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                              Icons.menu_book_outlined,
                              size: 18,
                              color: Color(0xFF7F2500)),
                          const SizedBox(width: 8),
                          Text(
                              'Mengenal ${info.nama}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(0xFF7F2500))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(info.desc,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 22.75 / 14,
                              color:
                                  AppColors.chocolate)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Color(0xFF7F2500)),
                    const SizedBox(width: 8),
                    Text(
                        'Fakta Menarik (Fun Facts)',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7F2500))),
                  ],
                ),
                const SizedBox(height: 12),
                _factCard(AppColors.primary,
                    'Tahukah Kamu?', info.fakta),
                const SizedBox(height: 12),
                _factCard(AppColors.amber, 'Cara Simpan',
                    'Simpan dalam wadah tertutup agar aroma tidak menguap.'),
                const SizedBox(height: 12),
                _factCard(AppColors.secondary,
                    'Tips Beli',
                    'Beli sedikit tapi sering lebih baik dari stok lama.'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                        Icons.hub_outlined,
                        size: 18,
                        color: Color(0xFF7F2500)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                          'Cocok Dikombinasikan Dengan',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7F2500))),
                    ),
                    const Text('Pasangan\nAromatik',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors
                                .chocolateMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pairs.map((b) {
                    final target =
                        _findIngredient(b);
                    return GestureDetector(
                      onTap: () {
                        if (target == null) {
                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      'Artikel $b segera hadir.')));
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ArticleScreen(
                                        repo: repo,
                                        info: target)),
                          );
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius:
                              BorderRadius.circular(
                                  9999),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration:
                                  const BoxDecoration(
                                color: Color(0xFF7F2500),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(b,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors
                                        .chocolate)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openRecipes(nResep),
                    icon: const Icon(
                        Icons.arrow_forward,
                        size: 18),
                    label: Text(
                        'Lihat Resep dengan Bahan Ini ($nResep Resep)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14)),
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

  /// Pil fakta ala Figma: sand penuh + lingkaran ikon putih.
  Widget _factPill(
      IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors
                            .chocolateMuted)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.chocolate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu fakta aksen kiri ala Figma.
  Widget _factCard(
      Color accent, String title, String body) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          20, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: accent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chocolate)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  height: 22.75 / 14,
                  color: AppColors.chocolateMuted)),
        ],
      ),
    );
  }

  String _karakterDefault(String kat) {
    switch (kat) {
      case 'Cabai':
        return 'Pedas & Segar';
      case 'Bawang':
        return 'Gurih & Aromatik';
      case 'Bumbu Daun':
        return 'Wangi & Segar';
      case 'Penyegar':
        return 'Asam & Segar';
      default:
        return 'Hangat & Gurih';
    }
  }

  IngredientInfo? _findIngredient(String name) {
    final q = name.toLowerCase();
    for (final e in widget.repo.encyclopedia) {
      if (e.nama.toLowerCase() == q) return e;
    }
    for (final e in widget.repo.encyclopedia) {
      if (e.nama.toLowerCase().contains(q) ||
          q.contains(e.nama.toLowerCase())) {
        return e;
      }
    }
    return null;
  }

  void _openRecipes(int n) {
    final key =
        widget.info.nama.toLowerCase().split(' ').first;
    final hits = widget.repo.searchTitle(widget.info.nama);
    final scored = widget.repo.search({key});
    final all = [
      ...hits,
      ...scored.top3,
      ...scored.rest
    ];
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
              repo: widget.repo, recipe: uniq.first)),
    );
  }
}
