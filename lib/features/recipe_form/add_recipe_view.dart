import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/recipe_repository.dart';

/// Tulis resep ala Stitch: preview foto otomatis + nama + cerita +
/// waktu/porsi/sulit + kategori + gizi AI + bahan + langkah + terbit.
/// Upload foto manual = M7 (placeholder kategori, tanpa Storage).
class AddRecipeScreen extends StatefulWidget {
  final RecipeRepository repo;
  const AddRecipeScreen({super.key, required this.repo});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _category = 'Unggas';
  String _duration = '30 mnt';
  String _serving = '2-3 Porsi';
  String _difficulty = 'Mudah';
  final List<TextEditingController> _ings = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  final List<TextEditingController> _steps = [TextEditingController()];

  static const _cats = [
    'Unggas',
    'Daging',
    'Seafood',
    'Nabati',
    'Telur',
    'Dessert',
    'Minuman',
    'Hidangan Utama',
    'Lainnya'
  ];
  static const _durations = [
    '15 mnt',
    '30 mnt',
    '45 mnt',
    '60 mnt',
    '90 mnt'
  ];
  static const _servingOptions = [
    '1-2 Porsi',
    '2-3 Porsi',
    '4-5 Porsi',
    '6+ Porsi'
  ];
  static const _difficulties = ['Mudah', 'Sedang', 'Sulit'];

  static const _catPhoto = {
    'Unggas': 0, 'Daging': 0, 'Seafood': 1, 'Nabati': 2,
    'Telur': 3, 'Dessert': 4, 'Minuman': 4, 'Hidangan Utama': 5,
    'Lainnya': 5,
  };

  @override
  Widget build(BuildContext context) {
    final preview =
        FoodPhotos.fallback[_catPhoto[_category]! % FoodPhotos.fallback.length];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tulis Resep Baru'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('Draf')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Foto Masakan',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: AppImage(
                  url: preview, fallbackLetter: _category),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Foto otomatis sesuai kategori • upload manual aktif M7.',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.chocolateMuted),
          ),
          const SizedBox(height: 16),
          const Text('Nama Resep',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                hintText: 'Misal: Ayam Balado Daun Jeruk'),
          ),
          const SizedBox(height: 16),
          const Text('Cerita & Deskripsi (opsional)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Ceritakan aroma atau tips penyajian...'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _pick('WAKTU', _duration, _durations,
                      (v) => setState(() => _duration = v!))),
              const SizedBox(width: 8),
              Expanded(
                  child: _pick('PORSI', _serving, _servingOptions,
                      (v) => setState(() => _serving = v!))),
              const SizedBox(width: 8),
              Expanded(
                  child: _pick(
                      'KESULITAN',
                      _difficulty,
                      _difficulties,
                      (v) =>
                          setState(() => _difficulty = v!))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Pilih Kategori Makanan',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cats.map((c) {
              final sel = _category == c;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.sand,
                labelStyle: TextStyle(
                    color: sel
                        ? Colors.white
                        : AppColors.chocolate,
                    fontWeight: FontWeight.w600),
                shape: const StadiumBorder(),
                onSelected: (_) =>
                    setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Hitung Nutrisi AI Gemini',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                    Spacer(),
                    Chip(label: Text('Estimasi AI')),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nilai gizi dihitung otomatis saat resep dibuka (butuh internet + API key, aktif M3).',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.chocolateMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Hitung AI aktif di M3 — butuh API key Gemini.'))),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                        'Perbarui Hitungan Gizi (AI)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _dynamicSection('Bahan Masakan (min 3)', _ings),
          _dynamicSection('Langkah Memasak (min 1)', _steps),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () => _save(false),
              child: const Text('Simpan Draf (privat)')),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _save(true),
            icon: const Icon(Icons.publish),
            label: const Text('Terbitkan Resep'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pick(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.chocolateMuted)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.chocolate,
                fontSize: 13),
            items: items
                .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dynamicSection(
      String title, List<TextEditingController> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                          hintText:
                              '${title.split(' ').first} ${e.key + 1}'),
                    ),
                  ),
                  if (list.length > 1)
                    IconButton(
                      icon:
                          const Icon(Icons.delete_outline),
                      onPressed: () =>
                          setState(() => list.removeAt(e.key)),
                    ),
                ],
              ),
            )),
        TextButton.icon(
          onPressed: () =>
              setState(() => list.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _save(bool publish) {
    final ings =
        _ings.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    final steps =
        _steps.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (_title.text.trim().isEmpty ||
        ings.length < 3 ||
        steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Lengkapi: judul + min 3 bahan + min 1 langkah')),
      );
      return;
    }
    widget.repo.addCustom(
      title: _title.text.trim(),
      category: _category,
      ingredients: ings,
      steps: steps,
      publish: publish,
      description: _desc.text.trim(),
      durationText: _duration,
      difficulty: _difficulty,
      servings: _serving,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(publish
              ? 'Resep diterbitkan ke pool publik!'
              : 'Draf tersimpan privat.')),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    for (final c in [..._ings, ..._steps]) {
      c.dispose();
    }
    super.dispose();
  }
}
