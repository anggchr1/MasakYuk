import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
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
  bool _bahanOpen = true;

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
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            centerTitle: true,
            title: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.9),
                borderRadius:
                    BorderRadius.circular(9999),
              ),
              child: const Text('Resep',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolate)),
            ),
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
                  child: IconButton(
                    icon: const Icon(Icons.share,
                        color: AppColors.chocolate),
                    onPressed: () =>
                        SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${r.title}\n\nBahan:\n${r.ingredientsRaw.join('\n')}\n\n— via MasakYuk',
                      ),
                    ),
                  ),
                ),
              ),
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
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.65,
                              color: AppColors.chocolate)),
                      const SizedBox(height: 4),
                      Text(
                        r.description.isEmpty
                            ? r.category
                            : r.description,
                        style: const TextStyle(
                            fontSize: 14,
                            color:
                                AppColors.chocolateMuted),
                      ),
                      const SizedBox(height: 12),
                      _metaBar(r.displayDuration,
                          r.displayDifficulty),
                      const SizedBox(height: 12),
                      _priceBox(e.min, e.max, e.complete),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _export,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color:
                                        const Color(0xFFDEC0B7)
                                            .withValues(
                                                alpha: 0.7)),
                                shape:
                                    const StadiumBorder(),
                              ),
                              icon: const Icon(
                                  Icons.image_outlined,
                                  size: 18),
                              label: const Text(
                                  'Export Gambar Resep',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color:
                                        const Color(0xFFDEC0B7)
                                            .withValues(
                                                alpha: 0.7)),
                                shape:
                                    const StadiumBorder(),
                              ),
                              icon: const Icon(
                                  Icons.store_outlined,
                                  size: 18),
                              label: const Text(
                                  'Buka Bahan di Maps',
                                  textAlign:
                                      TextAlign.center,
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
                      Row(
                        children: [
                          const Text('Bahan',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.chocolate)),
                          const SizedBox(width: 8),
                          Text(
                            '(${r.ingredientsRaw.length} bahan)',
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors
                                    .chocolateMuted),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() =>
                                _bahanOpen = !_bahanOpen),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius:
                                    BorderRadius.circular(
                                        9999),
                              ),
                              child: Icon(
                                  _bahanOpen
                                      ? Icons
                                          .keyboard_arrow_up
                                      : Icons
                                          .keyboard_arrow_down,
                                  size: 18,
                                  color: AppColors
                                      .chocolateMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_bahanOpen)
                        Screenshot(
                          controller: _shot,
                          child: Container(
                            padding:
                                const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius:
                                  BorderRadius.circular(
                                      32),
                            ),
                            child: Column(
                              children: [
                                ...r.ingredientsRaw
                                    .asMap()
                                    .entries
                                    .map(
                                  (e2) {
                                    final checked = _dp
                                        .checked
                                        .contains(e2.key);
                                    return Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                                  bottom:
                                                      10),
                                      child: _bahanRow(
                                          e2.value,
                                          checked,
                                          () => _dp.toggle(
                                              e2.key)),
                                    );
                                  },
                                ),
                              ],
                            ),
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
            height: 56,
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

  /// Bar WAKTU + KESULITAN ala Figma: pil sand berisi dua grup + divider.
  Widget _metaBar(String waktu, String sulit) {
    Widget group(IconData icon, String label, String value) {
      return Expanded(
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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color:
                            AppColors.chocolateMuted)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chocolate)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          group(Icons.timer_outlined, 'WAKTU', waktu),
          Container(
            width: 1,
            height: 32,
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.6),
          ),
          group(Icons.bar_chart, 'KESULITAN', sulit),
        ],
      ),
    );
  }

  Widget _priceBox(int min, int max, bool complete) {
    final String badge;
    final String desc;
    if (complete) {
      badge = '${Money.range(min, max)} • estimasi';
      desc =
          'Harga dihitung dari harga rata-rata bahan di pasar tradisional dan warung terdekat. Realisasi pengeluaran dapat bervariasi sesuai musim.';
    } else {
      badge = 'estimasi sebagian';
      desc = 'Sebagian bahan belum ada data harga.';
    }
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Perkiraan Belanja',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chocolate)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.chocolateMuted),
          ),
        ],
      ),
    );
  }

  /// Baris bahan ala Figma: pil putih + checkbox 22px + badge "Siap".
  Widget _bahanRow(
      String text, bool checked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: checked
                    ? null
                    : Border.all(
                        color:
                            AppColors.chocolateMuted),
              ),
              child: checked
                  ? const Icon(Icons.check,
                      size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: checked
                      ? FontWeight.w400
                      : FontWeight.w500,
                  color: checked
                      ? AppColors.chocolateMuted
                      : AppColors.chocolate,
                  decoration: checked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (checked)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D5),
                  borderRadius:
                      BorderRadius.circular(9999),
                ),
                child: const Text('Siap',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary)),
              ),
          ],
        ),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolate)),
              const Spacer(),
              Text(
                  cnt > 0
                      ? '${avg.toStringAsFixed(1)} ($cnt ulasan)'
                      : 'Belum ada rating',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chocolateMuted)),
            ],
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Beri Bintang Resep:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate)),
                  const Spacer(),
                  ...List.generate(
                      5,
                      (i) => IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: const Color(0xFFDEC0B7)
                            .withValues(alpha: 0.5)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (list.isEmpty)
                      const Text(
                          'Belum ada ulasan. Jadilah yang pertama!',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors
                                  .chocolateMuted)),
                    ...list.take(1).map((c) => Container(
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    16),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        AppColors.secondary,
                                    child: Text(
                                        c.user.isEmpty
                                            ? '?'
                                            : c.user[0]
                                                .toUpperCase(),
                                        style:
                                            const TextStyle(
                                                color: Colors
                                                    .white,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight
                                                        .w700)),
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  Expanded(
                                    child: Text(c.user,
                                        style:
                                            const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                                fontSize:
                                                    13)),
                                  ),
                                  Text(
                                    timeago.format(c.at,
                                        locale: 'id'),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors
                                            .chocolateMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(c.text,
                                  style: const TextStyle(
                                      fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
