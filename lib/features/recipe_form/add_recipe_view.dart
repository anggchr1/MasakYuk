import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/money.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';

/// Tambah Figma: header Batal/Simpan + tips + foto judul live +
/// angka Waktu/Porsi + toggle komunitas + Draf/Terbitkan.
/// Upload foto & status editable = M7 (pill status auto).
class AddRecipeScreen extends StatefulWidget {
  final RecipeRepository repo;
  final Recipe? existing; // mode Ubah bila diisi
  final VoidCallback? onNeedLogin; // dipanggil bila tamu ingin menyimpan
  const AddRecipeScreen(
      {super.key, required this.repo, this.existing, this.onNeedLogin});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _waktu = TextEditingController(text: '35');
  final _porsi = TextEditingController(text: '4');
  String _category = 'Tradisional';
  bool _publish = true;
  bool _saving = false;
  final List<TextEditingController> _ings = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];
  final List<TextEditingController> _steps = [TextEditingController()];

  static const _cats = [
    'Tradisional',
    'Sarapan',
    'Pedas',
    'Cepat & Mudah',
    'Seafood',
  ];
  static const _catPhoto = {
    'Tradisional': 0,
    'Sarapan': 3,
    'Pedas': 1,
    'Cepat & Mudah': 5,
    'Seafood': 1,
    'Unggas': 0,
    'Daging': 0,
    'Nabati': 2,
    'Telur': 3,
    'Dessert': 4,
    'Minuman': 4,
    'Hidangan Utama': 5,
    'Lainnya': 5,
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _title.text = e.title;
    _desc.text = e.description;
    _category = e.category;
    _publish = e.isPublished;
    final w =
        RegExp(r'(\d+)').firstMatch(e.durationText ?? '');
    if (w != null) _waktu.text = w.group(1)!;
    final p =
        RegExp(r'(\d+)').firstMatch(e.servings ?? '');
    if (p != null) _porsi.text = p.group(1)!;
    if (e.estCostManual != null) {
      _price.text = '${e.estCostManual}';
    }
    _ings
      ..clear()
      ..addAll(e.ingredientsRaw
          .map((s) => TextEditingController(text: s)));
    _steps
      ..clear()
      ..addAll(e.stepsList
          .map((s) => TextEditingController(text: s)));
  }

  @override
  Widget build(BuildContext context) {
    final preview = FoodPhotos
            .fallback[_catPhoto[_category]! % FoodPhotos.fallback.length];
    final shownTitle = _title.text.trim().isEmpty
        ? 'Judul Masakan Anda'
        : _title.text.trim();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.chocolate,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 14, color: AppColors.chocolate),
          label: const Text('Batal',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chocolate)),
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.only(left: 8)),
        ),
        leadingWidth: 90,
        title: const Column(
          children: [
            Text('Resep Baru',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chocolate)),
            Text('Koleksi Dapur Rumahan',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chocolateMuted)),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: _saving ? null : () => _save(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check,
                          size: 14,
                          color: AppColors.chocolate),
                      SizedBox(width: 4),
                      Text('Simpan',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.chocolate)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.soup_kitchen,
                    color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Fokus Memasak Nyata',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      Text(
                        'Foto hidangan disajikan otomatis berdasarkan kategori hidangan. Tak perlu repot memotret langkah di dapur yang berminyak!',
                        style: TextStyle(
                            fontSize: 12,
                            height: 19.5 / 12,
                            color: AppColors
                                .chocolateMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 176,
                  width: double.infinity,
                  child: AppImage(
                      url: preview,
                      fallbackLetter: _category),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.0),
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.2),
                        const Color(0xFF3D2314)
                            .withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.9),
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_menu,
                          size: 14,
                          color: AppColors.chocolate),
                      const SizedBox(width: 6),
                      Text(
                        'Foto Kategori: $_category',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.chocolate),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(shownTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Text(
                        'Sentuhan bumbu dapur otentik keluarga',
                        style: TextStyle(
                            color: Color(0xFFFFC9B7),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: Text('Kategori Resep',
                    style: TextStyle(
                        fontWeight: FontWeight.w700)),
              ),
              Text('Pilih satu untuk tema foto',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.chocolateMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._cats,
              if (!_cats.contains(_category)) _category,
            ].map((c) {
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
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chocolate),
                    children: [
                      TextSpan(text: 'Nama Resep '),
                      TextSpan(
                          text: '*',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.w400,
                              color: Color(0xFF7F2500))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText:
                          'Contoh: Ayam Bakar Bumbu Rujak Mertua'),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chocolate),
                    children: [
                      TextSpan(
                          text: 'Cerita Resep '),
                      TextSpan(
                          text: '(Opsional)',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.w400,
                              color: AppColors
                                  .chocolateMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText:
                          'Tuliskan sedikit asal-usul atau rahasia kenikmatan bumbu ini...'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _numberBox('Waktu', _waktu,
                      'mnt', Icons.schedule)),
              const SizedBox(width: 8),
              Expanded(
                  child: _numberBox('Porsi', _porsi,
                      'orang', Icons.group)),
            ],
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
                Row(
                  children: const [
                    Icon(Icons.payments_outlined,
                        color: AppColors.primary,
                        size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Estimasi Belanja Bahan',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                    Chip(
                        label: Text('±Rp • estimasi sebagian')),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '35000',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (_priceValue() != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 6),
                    child: Text(
                      _pricePreview(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                const SizedBox(height: 6),
                const Text(
                  '*Disusun transparan sebagai panduan harga pasar tradisional domestik, dapat berbeda di setiap daerah.',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.chocolateMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Bahan-Bahan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text(
                        'Tentukan takaran dan status persiapan dapur',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors
                                .chocolateMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() =>
                    _ings.add(TextEditingController())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAE0),
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add,
                          size: 12,
                          color: Color(0xFF7F2500)),
                      SizedBox(width: 4),
                      Text('Tambah',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7F2500))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ..._ings.asMap().entries.map((e) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDEC0B7)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator,
                          size: 18,
                          color:
                              AppColors.chocolateMuted),
                      const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        onChanged: (_) =>
                            setState(() {}),
                        decoration: InputDecoration(
                            hintText:
                                'Bahan ${e.key + 1}'),
                      ),
                    ),
                    if (e.value.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius:
                              BorderRadius.circular(
                                  9999),
                        ),
                        child: Text(
                          Recipe.prepStatus(
                              e.value.text),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors
                                  .chocolateMuted),
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                          Icons.delete_outline,
                          size: 20),
                      onPressed: _ings.length > 1
                          ? () => setState(
                              () => _ings.removeAt(e.key))
                          : null,
                    ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Langkah Memasak',
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                    Text(
                        'Tahapan praktis yang mudah diikuti pembaca',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors
                                .chocolateMuted)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() =>
                    _steps.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Langkah'),
              ),
            ],
          ),
          ..._steps.asMap().entries.map((e) => Container(
                margin:
                    const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor:
                                AppColors.primary,
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w800)),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18),
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(),
                            onPressed: _steps.length > 1
                                ? () => setState(() =>
                                    _steps.removeAt(
                                        e.key))
                                : null,
                          ),
                        ],
                      ),
                      TextField(
                        controller: e.value,
                        maxLines: 3,
                        decoration: InputDecoration(
                            hintText:
                                'Langkah ${e.key + 1}...'),
                      ),
                    ],
                  ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.lock_open,
                      size: 18,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Terbuka untuk Komunitas',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 13)),
                      Text(
                          'Resep dapat dicari dan disukai pengguna lain',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors
                                  .chocolateMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: _publish,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _publish = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _save(false),
                    icon: const Icon(
                        Icons.inventory_2_outlined,
                        size: 18),
                    label:
                        const Text('Simpan Draf'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _save(_publish),
                    icon: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 18),
                    label:
                        const Text('Terbitkan Resep'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _numberBox(String label, TextEditingController ctrl,
      String unit, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.chocolateMuted)),
            ],
          ),
        ],
      ),
    );
  }

  int? _priceValue() => int.tryParse(
      _price.text.replaceAll(RegExp(r'[^0-9]'), ''));

  String _pricePreview() {
    final v = _priceValue() ?? 0;
    final lo = Money.rp((v * 0.75).round());
    final hi = Money.rp((v * 1.25).round());
    return 'Perkiraan $lo - $hi (estimasi)';
  }

  Future<void> _save(bool publish) async {
    if (_saving) return;
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

    // Tamu tidak punya token: resep hanya bisa masuk ke akun.
    if (widget.repo.api.token == null) {
      final mauMasuk = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Masuk dulu, ya'),
          content: const Text(
              'Resep barumu disimpan ke akun. Masuk dengan Google untuk '
              'melanjutkan.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Nanti')),
            ElevatedButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Masuk')),
          ],
        ),
      );
      if (mauMasuk == true && mounted) {
        Navigator.pop(context); // tutup form
        widget.onNeedLogin?.call(); // tamu keluar -> layar login
      }
      return;
    }

    final ex = widget.existing;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _publish = publish;
    });
    final manual = _priceValue();
    try {
      if (ex == null) {
        await widget.repo.addCustom(
          title: _title.text.trim(),
          category: _category,
          ingredients: ings,
          steps: steps,
          publish: publish,
          description: _desc.text.trim(),
          durationText: '${_waktu.text.trim()} mnt',
          servings: '${_porsi.text.trim()} orang',
          estCostManual: manual,
        );
      } else {
        await widget.repo.updateCustom(
          ex.docId,
          title: _title.text.trim(),
          category: _category,
          ingredients: ings,
          steps: steps,
          publish: publish,
          description: _desc.text.trim(),
          durationText: '${_waktu.text.trim()} mnt',
          servings: '${_porsi.text.trim()} orang',
          estCostManual: manual,
        );
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
            content: Text(ex == null
                ? (publish
                    ? 'Resep diterbitkan ke pool publik!'
                    : 'Draf tersimpan privat.')
                : 'Resep diperbarui!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: ${_pesan(e)}')));
    }
  }

  String _pesan(Object e) {
    if (e is ApiException) {
      if (e.status == 401) return 'sesi berakhir, masuk ulang.';
      if (e.status == 422) return 'data belum valid.';
      return 'server menolak (${e.status}).';
    }
    return 'periksa koneksi ke server.';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _waktu.dispose();
    _porsi.dispose();
    for (final c in [..._ings, ..._steps]) {
      c.dispose();
    }
    super.dispose();
  }
}
