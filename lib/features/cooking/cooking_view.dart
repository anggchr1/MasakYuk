import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import 'cooking_provider.dart';

/// Mode memasak ala Stitch: foto + estimasi + timer jalan beneran
/// + bahan langkah ini + tips + navigasi tahap + lanjut/selesai.
/// Kontrol suara & foto per langkah DIBUANG (keputusan tim).
class CookingScreen extends StatefulWidget {
  final RecipeRepository repo;
  final Recipe recipe;
  const CookingScreen(
      {super.key, required this.repo, required this.recipe});

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  late final CookingProvider _cp;

  static const _tips = [
    'Jangan masak dengan api terlalu besar agar bumbu meresap dan tidak gosong.',
    'Cicipi dan koreksi rasa di akhir — garam sedikit dulu, tambah bila kurang.',
    'Diamkan masakan 5 menit sebelum disajikan agar rasa menyatu.',
    'Siapkan semua bahan sebelum menyalakan kompor.',
  ];

  @override
  void initState() {
    super.initState();
    _cp = CookingProvider(widget.recipe.stepsList.length);
    if (widget.recipe.stepsList.isNotEmpty) {
      _cp.retarget(CookingProvider.secsFor(
          widget.recipe.stepsList.first));
    }
  }

  String _clip(String s) {
    final words = s.split(RegExp(r'\s+'));
    if (words.length <= 8) return s;
    return '${words.take(8).join(' ')}...';
  }

  int _mins(String s) =>
      (CookingProvider.secsFor(s) / 60).round().clamp(1, 60);

  /// Nama tahap ala desain (Marinasi/Goreng/...) dari kata kunci langkah.
  String _stage(String s) {
    final t = s.toLowerCase();
    if (t.contains('goreng')) return 'Menggoreng';
    if (t.contains('rebus') || t.contains('didih')) {
      return 'Merebus';
    }
    if (t.contains('tumis')) return 'Menumis';
    if (t.contains('bakar') || t.contains('panggang')) {
      return 'Memanggang';
    }
    if (t.contains('kukus')) return 'Mengukus';
    if (t.contains('potong') ||
        t.contains('iris') ||
        t.contains('cincang')) {
      return 'Memotong';
    }
    if (t.contains('campur') || t.contains('aduk')) {
      return 'Mencampur';
    }
    if (t.contains('saji') || t.contains('hidang')) {
      return 'Penyajian';
    }
    if (t.contains('marinasi') ||
        t.contains('rendam') ||
        t.contains('diamkan')) {
      return 'Marinasi';
    }
    if (t.contains('blender') ||
        t.contains('halus') ||
        t.contains('ulek')) {
      return 'Menghaluskan';
    }
    return 'Memasak';
  }

  /// Bahan yang disebut di langkah ini (cocokkan keyword).
  List<String> _stepIngredients(String step) {
    final s = step.toLowerCase();
    return widget.recipe.ingredientsRaw.where((ing) {
      final toks = ing
          .toLowerCase()
          .split(RegExp(r'[^a-z]+'))
          .where((w) => w.length >= 4);
      return toks.any(s.contains);
    }).take(6).toList();
  }

  void _nav(void Function() go, String step) {
    go();
    _cp.retarget(CookingProvider.secsFor(step));
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.stepsList;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.chocolate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('MODE MEMASAK',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.55,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chocolateMuted)),
            Text(widget.recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chocolate)),
          ],
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _cp,
        builder: (_, _) {
          if (steps.isEmpty) {
            return const Center(
                child: Text('Tidak ada langkah.'));
          }
          final step = steps[_cp.index];
          final pct = (_cp.progress * 100).round();
          final ings = _stepIngredients(step);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  Text(
                    'Langkah ${_cp.index + 1} dari ${steps.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  Text('$pct% Selesai',
                      style: const TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.chocolateMuted)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: _cp.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.sand,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      height: 224,
                      width: double.infinity,
                      child: AppImage(
                        url: photoFor(widget.recipe),
                        fallbackLetter:
                            widget.recipe.title,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.55),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Estimasi: ${_mins(step)} Menit',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D5),
                  borderRadius:
                      BorderRadius.circular(9999),
                ),
                child: Text('Tahap ${_stage(step)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7F2500))),
              ),
              const SizedBox(height: 8),
              Text(
                'Langkah ${_cp.index + 1}: ${_clip(step)}',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.65,
                    color: AppColors.chocolate,
                    height: 34 / 26),
              ),
              const SizedBox(height: 8),
              Text(step,
                  style: const TextStyle(
                      fontSize: 16,
                      height: 26 / 16,
                      color: AppColors.chocolateMuted)),
              const SizedBox(height: 16),
              _timerCard(),
              if (ings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.kitchen,
                              size: 18,
                              color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Bahan di Langkah Ini',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: AppColors
                                        .chocolate)),
                          ),
                          Text('Centang jika sudah masuk',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors
                                      .chocolateMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...ings.map((ing) {
                        final checked = _cp.boxChecked
                            .contains(ing);
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 8),
                          child: GestureDetector(
                            onTap: () =>
                                _cp.toggleBox(ing),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration:
                                        BoxDecoration(
                                      color: checked
                                          ? AppColors
                                              .primary
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  6),
                                      border: checked
                                          ? null
                                          : Border.all(
                                              color: const Color(
                                                  0xFFDEC0B7)),
                                    ),
                                    child: checked
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors
                                                .white)
                                        : null,
                                  ),
                                  const SizedBox(
                                      width: 12),
                                  Expanded(
                                    child: Text(ing,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color: checked
                                              ? AppColors
                                                  .chocolateMuted
                                              : AppColors
                                                  .chocolate,
                                          decoration: checked
                                              ? TextDecoration
                                                  .lineThrough
                                              : null,
                                        )),
                                  ),
                                  if (checked)
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                                  horizontal:
                                                      10,
                                                  vertical:
                                                      2),
                                      decoration:
                                          BoxDecoration(
                                        color: const Color(
                                            0xFFFFE2D5),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    9999),
                                      ),
                                      child: const Text(
                                          'Siap',
                                          style: TextStyle(
                                              fontSize:
                                                  11,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                              color: Color(
                                                  0xFF7F2500))),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D5)
                      .withValues(alpha: 0.6),
                  borderRadius:
                      BorderRadius.circular(32),
                  border: Border.all(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Tips Chef',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.chocolate)),
                          const SizedBox(height: 3),
                          Text(
                            _tips[widget.recipe.docId.hashCode
                                    .abs() %
                                _tips.length],
                            style: const TextStyle(
                                fontSize: 12,
                                height: 19.5 / 12,
                                color: AppColors
                                    .chocolate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('NAVIGASI SELURUH TAHAP:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.55,
                      color: AppColors.chocolateMuted)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: steps.asMap().entries.map((e) {
                    final active = e.key == _cp.index;
                    final done = e.key < _cp.index;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _nav(
                            () => _cp.jumpTo(e.key),
                            e.value),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.sand,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${e.key + 1}. ${_stage(e.value)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: active
                                      ? Colors.white
                                      : AppColors.chocolate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              done
                                  ? const Icon(Icons.check,
                                      size: 14,
                                      color:
                                          AppColors.primary)
                                  : Text(
                                      active
                                          ? 'Aktif'
                                          : 'Nanti',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                                .withValues(
                                                    alpha:
                                                        0.9)
                                            : AppColors
                                                .chocolateMuted,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      // Dibungkus AnimatedBuilder agar label tombol & status back
      // ikut update saat pindah langkah (bug: macet di "Langkah 2").
      bottomNavigationBar: AnimatedBuilder(
        animation: _cp,
        builder: (_, _) => Container(
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
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.sand,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.chocolate),
                  onPressed: _cp.index == 0
                      ? null
                      : () => _nav(_cp.prev,
                          steps[_cp.index - 1]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cp.isLast
                        ? () => _finish(context)
                        : () => _nav(_cp.next,
                            steps[_cp.index + 1]),
                    child: Text(_cp.isLast
                        ? 'Selesaikan 🎉'
                        : 'Lanjut ke Langkah ${_cp.index + 2} →'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _timerCard() {
    return Container(
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
              const Icon(Icons.timer_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pengatur Waktu Langkah',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chocolate),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(9999),
                  border: Border.all(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Otomatis Berdering',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.chocolateMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cp.clock,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: AppColors.chocolate,
                        ),
                      ),
                      Text(
                        _cp.targetLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.chocolateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.sand,
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.chocolate,
                    ),
                    onPressed: _resetStepTimer,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.sand,
                  child: TextButton(
                    onPressed: _cp.addMinute,
                    child: const Text(
                      '+1',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: Icon(
                      _cp.running
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _cp.toggleTimer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetStepTimer() {
    _cp.retarget(
        CookingProvider.secsFor(widget.recipe.stepsList[_cp.index]));
  }
  /// Dialog selesai ala Stitch (icon kit): ikon + judul + desc
  /// + tombol sejajar [Nanti | Simpan], bukan menumpuk.
  void _finish(BuildContext context) {
    final already =
        widget.repo.isFavorite(widget.recipe.docId);
    final msg = already
        ? 'Resep ini sudah ada di favoritmu. Selamat menikmati!'
        : 'Simpan ${widget.recipe.title} ke favorit?';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.celebration,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Masakan selesai!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.chocolate)),
            const SizedBox(height: 8),
            Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.chocolateMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sand,
                      foregroundColor: AppColors.chocolate,
                      elevation: 0,
                    ),
                    child: const Text('Nanti'),
                  ),
                ),
                if (!already) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.repo.toggleFavorite(
                            widget.recipe.docId);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cp.dispose();
    super.dispose();
  }
}
