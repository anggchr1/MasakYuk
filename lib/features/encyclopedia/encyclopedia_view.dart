import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/recipe_repository.dart';
import 'article_view.dart';

/// Indeks ensiklopedia: search + chip kategori + sortir A-Z + grid.
/// Data: assets/encyclopedia.json (48 bahan, review akurasi manual).
class EncyclopediaScreen extends StatefulWidget {
  final RecipeRepository repo;
  const EncyclopediaScreen({super.key, required this.repo});

  @override
  State<EncyclopediaScreen> createState() =>
      _EncyclopediaScreenState();
}

class _EncyclopediaScreenState
    extends State<EncyclopediaScreen> {
  String _q = '';
  String _kat = 'Semua';
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final kats = [
      'Semua',
      ...{
        for (final e in widget.repo.encyclopedia) e.kat
      }
    ];
    var items = widget.repo.encyclopedia.where((e) {
      final okQ = _q.isEmpty ||
          e.nama.toLowerCase().contains(_q) ||
          e.desc.toLowerCase().contains(_q);
      final okK = _kat == 'Semua' || e.kat == _kat;
      return okQ && okK;
    }).toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ensiklopedia Bahan'),
            Text('Khazanah Rempah & Bumbu Nusantara',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(
                () => _q = v.toLowerCase().trim()),
            decoration: const InputDecoration(
              hintText: 'Cari bahan atau rempah dapur...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kats.map((k) {
                final sel = _kat == k;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(k),
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
                        setState(() => _kat = k),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Bahan Dapur Populer (${items.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolate)),
              const Spacer(),
              const Text('A-Z ↑',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final e = items[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ArticleScreen(
                            repo: widget.repo,
                            info: e)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        color: AppColors.primaryContainer,
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                e.nama.isEmpty
                                    ? '?'
                                    : e.nama[0],
                                style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight:
                                        FontWeight.w800,
                                    color: Colors.white70),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius:
                                      BorderRadius.circular(
                                          9999),
                                ),
                                child: Text(e.kat,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(e.nama,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 14)),
                            Text('Asal: ${e.asal}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors
                                        .chocolateMuted)),
                            const SizedBox(height: 6),
                            const Text(
                                'Pelajari →',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
