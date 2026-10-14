import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../cooking/cooking_view.dart';
import '../encyclopedia/encyclopedia_view.dart';
import '../places/places_view.dart';
import 'detail_provider.dart';

/// Detail v2: hero + pita harga + export/maps/wiki + bahan +
/// tips + KOMENTAR & RATING + CTA. (Tanpa gizi/AI.)
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
  final _shot = ScreenshotController();
  final _cmt = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dp = DetailProvider();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final e = widget.repo.estCost(r);
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
                        color: Colors.black
                            .withValues(alpha: 0.45),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${r.category} • ${r.tags.take(3).join(' • ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12),
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
                  animation:
                      Listenable.merge([_dp, widget.repo]),
                  builder: (_, _) => Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      _priceBox(e.min, e.max, e.complete),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _export,
                              icon: const Icon(
                                  Icons.image_outlined,
                                  size: 18),
                              label: const Text(
                                  'Export Gambar',
                                  style: TextStyle(
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PlacesScreen(
                                            repo:
                                                widget.repo)),
                              ),
                              icon: const Icon(
                                  Icons.store_outlined,
                                  size: 18),
                              label: const Text(
                                  'Bahan di Maps',
                                  style: TextStyle(
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EncyclopediaScreen(
                                      repo: widget.repo)),
                        ),
                        icon: const Icon(Icons.menu_book,
                            size: 16),
                        label: const Text(
                            'Pelajari bahan di Wikipedia',
                            style:
                                TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingredient (${r.ingredientsRaw.length} bahan)',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate),
                      ),
                      const SizedBox(height: 8),
                      Screenshot(
                        controller: _shot,
                        child: Container(
                          color: AppColors.cream,
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 4),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 16)),
                              ...r.ingredientsRaw.map(
                                (ing) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 3),
                                  child: Row(
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: AppColors
                                                  .primary,
                                              fontWeight:
                                                  FontWeight
                                                      .w800)),
                                      Expanded(
                                          child:
                                              Text(ing)),
                                    ],
                                  ),
                                ),
                              ),
                              const Text(
                                  '— via MasakYuk',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors
                                          .chocolateMuted)),
                            ],
                          ),
                        ),
                      ),
                      ...r.ingredientsRaw.asMap().entries.map(
                            (e2) => CheckboxListTile(
                              value: _dp.checked
                                  .contains(e2.key),
                              onChanged: (_) =>
                                  _dp.toggle(e2.key),
                              title: Text(
                                e2.value,
                                style: TextStyle(
                                  decoration: _dp.checked
                                          .contains(e2.key)
                                      ? TextDecoration
                                          .lineThrough
                                      : null,
                                ),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity
                                      .leading,
                              contentPadding:
                                  EdgeInsets.zero,
                            ),
                          ),
                      const SizedBox(height: 12),
                      _comments(),
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
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.95),
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

  Widget _priceBox(int min, int max, bool complete) {
    final String badge;
    final String desc;
    if (complete) {
      badge = '${Money.range(min, max)} estimasi';
      desc = 'Dihitung dari harga pasar. Realisasi bisa berbeda.';
    } else {
      badge = 'estimasi sebagian';
      desc = 'Sebagian bahan belum ada data harga.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text('Perkiraan Belanja'),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.chocolateMuted),
          ),
        ],
      ),
    );
  }

  Widget _comments() {
    final r = widget.recipe;
    final list = widget.repo.commentsFor(r.docId);
    final avg = widget.repo.avgRating(r.docId);
    final cnt = widget.repo.ratingCount(r.docId);
    final mine = widget.repo.myRating(r.docId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Ulasan Dapur',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chocolate)),
            const Spacer(),
            if (cnt > 0)
              Text(
                  '★ ${avg.toStringAsFixed(1)} ($cnt ulasan)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Beri Bintang: ',
                style: TextStyle(fontSize: 13)),
            ...List.generate(
                5,
                (i) => IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        i < mine
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.amber,
                      ),
                      onPressed: () {
                        widget.repo.setRating(
                            r.docId, i + 1, r.title);
                        AppToast.show(
                          context,
                          'Bintang ${i + 1} tersimpan!',
                          'Terima kasih atas penilaianmu.',
                          icon: Icons.star,
                        );
                      },
                    )),
          ],
        ),
        const SizedBox(height: 4),
        if (list.isEmpty)
          const Text(
              'Belum ada ulasan. Jadilah yang pertama!',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.chocolateMuted)),
        ...list.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.sand,
                  child: Text(
                      c.user.isEmpty
                          ? '?'
                          : c.user[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                title: Text(c.user,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                subtitle: Text(c.text,
                    style:
                        const TextStyle(fontSize: 13)),
              ),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cmt,
                decoration: const InputDecoration(
                    hintText: 'Tulis ulasanmu...'),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send,
                    color: Colors.white, size: 18),
                onPressed: () {
                  final t = _cmt.text.trim();
                  if (t.isEmpty) return;
                  widget.repo
                      .addComment(r.docId, t);
                  _cmt.clear();
                  AppToast.show(
                    context,
                    'Ulasan terkirim!',
                    'Komentar tampil di bawah.',
                    icon: Icons.chat_bubble,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Export daftar bahan jadi gambar PNG → share/simpan.
  Future<void> _export() async {
    try {
      final bytes = await _shot.capture();
      if (bytes == null) throw 'gagal render';
      final dir = await getTemporaryDirectory();
      final f = File(
          '${dir.path}/bahan-${widget.recipe.docId}.png');
      await f.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(f.path)],
        text:
            'Bahan ${widget.recipe.title} — via MasakYuk',
      ));
    } catch (_) {
      if (mounted) {
        AppToast.show(context, 'Export gagal',
            'Coba lagi sesaat.',
            icon: Icons.error_outline);
      }
    }
  }

  @override
  void dispose() {
    _cmt.dispose();
    _dp.dispose();
    super.dispose();
  }
}
