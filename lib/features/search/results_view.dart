import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';

/// Hasil Figma: header + search + chip bahan + Tambah +
/// sortir + kartu match hijau + CTA besar.
class ResultsScreen extends StatefulWidget {
  final RecipeRepository repo;
  final String title;
  final String subtitle;
  final Set<String> inputs;
  final String? chip;
  final bool showAll;
  final List<Recipe>? initial;
  const ResultsScreen({
    super.key,
    required this.repo,
    this.title = 'Pencarian Bahan',
    this.subtitle = 'Good Morning, Chef!',
    Set<String>? inputs,
    this.chip,
    this.showAll = false,
    this.initial,
  }) : inputs = inputs ?? const {};

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Set<String> _inputs;
  late bool _showAll;
  String _sort = 'Kecocokan';
  static const _sorts = ['Kecocokan', 'Paling Cepat', 'Nama A-Z'];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inputs = Set.of(widget.inputs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showAll = widget.showAll;
  }

  List<Recipe> get _base {
    if (widget.initial != null) {
      return widget.initial!;
    }
    if (widget.chip != null && widget.chip != 'Semua') {
      return widget.repo.byDisplayCategory(widget.chip!);
    }
    final res = widget.repo.search(_inputs);
    return [...res.top3, ...res.rest];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        var items = _base;
        switch (_sort) {
          case 'Paling Cepat':
            items.sort((a, b) => a.stepsList.length
                .compareTo(b.stepsList.length));
            break;
          case 'Nama A-Z':
            items.sort(
                (a, b) => a.title.compareTo(b.title));
            break;
          default:
            break; // skor kecocokan
        }
        final shown =
            _showAll ? items : items.take(3).toList();
        final rest = items.length - shown.length;
        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('BAHAN DIGUNAKAN',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppColors
                                    .chocolateMuted)),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(_inputs.clear),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize:
                                const Size(0, 28),
                          ),
                          child: const Text('Reset',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(0xFF7F2500))),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._inputs.map((b) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                        right: 8),
                                child: Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 14,
                                      vertical: 6),
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                        0xFF7F2500),
                                    borderRadius:
                                        BorderRadius.circular(
                                            9999),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        b[0].toUpperCase() +
                                            b.substring(1),
                                        style:
                                            const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                color: Colors
                                                    .white),
                                      ),
                                      const SizedBox(
                                          width: 6),
                                      const Icon(
                                          Icons.check,
                                          size: 12,
                                          color:
                                              Colors.white),
                                    ],
                                  ),
                                ),
                              )),
                          GestureDetector(
                            onTap: _addIngredient,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        9999),
                                border: Border.all(
                                    color: AppColors
                                        .chocolateMuted,
                                    width: 1),
                              ),
                              child: const Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      size: 12,
                                      color: AppColors
                                          .chocolateMuted),
                                  SizedBox(width: 4),
                                  Text('+ Tambah',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: AppColors
                                              .chocolateMuted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paling Cocok (${items.length} Resep)',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors
                                        .chocolate),
                              ),
                              if (_inputs.isNotEmpty)
                                const Text(
                                  'Semua bahan utama tersedia di dapurmu',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors
                                          .chocolateMuted),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          margin:
                              const EdgeInsets.only(top: 8),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: DropdownButton<String>(
                            value: _sort,
                            underline: const SizedBox(),
                            borderRadius:
                                BorderRadius.circular(16),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors
                                    .chocolateMuted),
                            items: _sorts
                                .map((s) =>
                                    DropdownMenuItem(
                                        value: s,
                                        child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _sort = v!),
                          ),
                        ),
                      ],
                    ),
                    if (_inputs.isEmpty)
                      const Text(
                        'Menampilkan semua resep',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors
                                .chocolateMuted),
                      ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const EmptyState(
                        icon: Icons.search_off,
                        title: 'Tidak Ditemukan',
                        desc:
                            'Coba kata lain, kurangi bahan, atau tambah resep sendiri.',
                      )
                    else
                      ...shown.map((r) =>
                          _matchCard(r)),
                    if (!_showAll && rest > 0) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => setState(
                              () => _showAll = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF7F2500),
                          ),
                          child: Text(
                              'Lihat $rest resep lainnya dengan bahan tambahan →'),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 8, bottom: 8),
                          child: Text(
                            'Hanya perlu 1 atau 2 bumbu tambahan kecil',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors
                                    .chocolateMuted),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF7F2500),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white
                      .withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () =>
                        Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(widget.title.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFFFFB59C),
                              fontSize: 11,
                              letterSpacing: 0.55)),
                      Text(widget.subtitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800)),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.6),
                            width: 2),
                      ),
                      child: ClipOval(
                        child: AppImage(
                          url: FoodPhotos.avatar,
                          fallbackLetter:
                              widget.repo.userName,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star,
                            size: 10,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(9999),
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (v) {
                  final w = v
                      .toLowerCase()
                      .split(RegExp(r'[^a-z]+'))
                      .where((e) => e.length >= 3);
                  setState(() => _inputs.addAll(w));
                  _searchCtrl.clear();
                },
                decoration: InputDecoration(
                  hintText: _inputs.isEmpty
                      ? 'telur, tahu, kecap'
                      : _inputs.join(', '),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14),
                  prefixIcon: const Icon(Icons.search,
                      color:
                          AppColors.chocolateMuted),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_inputs.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 8),
                          child: CircleAvatar(
                            backgroundColor:
                                AppColors.sand,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close,
                                  size: 16,
                                  color: AppColors
                                      .chocolateMuted),
                              onPressed: () => setState(
                                  _inputs.clear),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircleAvatar(
                          backgroundColor:
                              Color(0xFF7F2500),
                          child: Icon(Icons.search,
                              color: Colors.white,
                              size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addIngredient() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Bahan'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'cth: bawang'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final w = c.text
                  .toLowerCase()
                  .split(RegExp(r'[^a-z]+'))
                  .where((e) => e.length >= 3);
              setState(() => _inputs.addAll(w));
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(Recipe r) {
    final m = _inputs.isEmpty
        ? 0
        : r.matchScore(_inputs);
    final e = widget.repo.estCost(r);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetailScreen(
                  repo: widget.repo, recipe: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 176,
                      width: double.infinity,
                      child: AppImage(
                          url: photoFor(r),
                          fallbackLetter: r.title),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
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
                  if (m > 0)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEAF5E9),
                          borderRadius:
                              BorderRadius.circular(
                                  9999),
                          border: Border.all(
                              color: const Color(
                                  0xFFC5E6C3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                Icons.task_alt,
                                size: 13,
                                color: Color(0xFF246A28)),
                            const SizedBox(width: 4),
                            Text(
                              '$m dari ${_inputs.length} bahan cocok!',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color:
                                      Color(0xFF246A28)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    6, 8, 6, 4),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.chocolate)),
                    if (r.description.isNotEmpty)
                      Text(r.description,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors
                                  .chocolateMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors
                                    .chocolateMuted),
                            const SizedBox(width: 4),
                            Text(r.displayDuration,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors
                                        .chocolateMuted)),
                          ],
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFE2D5),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: Text(
                              r.displayDifficulty,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color:
                                      Color(0xFF7F2500))),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: Text(
                            e.complete
                                ? '${Money.range(e.min, e.max)} • estimasi'
                                : 'estimasi sebagian',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white),
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
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
