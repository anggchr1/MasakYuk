import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/media/pilih_foto.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';

/// Tambah/Ubah resep — disamakan dengan form web:
/// kategori bisa lebih dari satu + tag baru, bahan punya takaran & satuan
/// (gram/kg/sdm/sdt/...), langkah punya durasi dan foto proses (maks 3).
/// Foto tanpa unggahan memakai foto kategori bawaan seperti di Flutter.
class AddRecipeScreen extends StatefulWidget {
  final RecipeRepository repo;
  final Recipe? existing; // mode Ubah bila diisi
  final VoidCallback? onNeedLogin; // dipanggil bila tamu ingin menyimpan
  const AddRecipeScreen(
      {super.key, required this.repo, this.existing, this.onNeedLogin});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

/// Satu baris bahan: nama + takaran + satuan.
class _BarisBahan {
  final nama = TextEditingController();
  final jumlah = TextEditingController();
  String satuan;

  _BarisBahan({String namaAwal = '', String jumlahAwal = '', this.satuan = 'gram'}) {
    nama.text = namaAwal;
    jumlah.text = jumlahAwal;
  }

  void dispose() {
    nama.dispose();
    jumlah.dispose();
  }
}

/// Grup bahan ("Bahan Utama", "Bumbu", ...).
class _GrupBahan {
  final judul = TextEditingController(text: 'Bahan Utama');
  final List<_BarisBahan> baris = [];

  _GrupBahan({String? judulAwal}) {
    if (judulAwal != null && judulAwal.trim().isNotEmpty) {
      judul.text = judulAwal.trim();
    }
  }

  void dispose() {
    judul.dispose();
    for (final b in baris) {
      b.dispose();
    }
  }
}

/// Foto proses satu langkah: bytes = belum diunggah, id = sudah di Cloudinary.
class _FotoLangkah {
  Uint8List? bytes;
  int? id;
  String? url;

  _FotoLangkah({this.bytes, this.id, this.url});
}

class _LangkahForm {
  final teks = TextEditingController();
  final menit = TextEditingController();
  final detik = TextEditingController();
  final List<_FotoLangkah> foto = [];

  void dispose() {
    teks.dispose();
    menit.dispose();
    detik.dispose();
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _porsi = TextEditingController(text: '4');
  final Set<String> _kategori = {'Tradisional'};
  final Set<String> _tagTambahan = {};
  bool _publish = true;
  bool _saving = false;
  // Foto sampul: bytes = belum diunggah, id = sudah ada di Cloudinary.
  Uint8List? _fotoBytes;
  String? _fotoUrl;
  int? _gambarId;
  final List<_GrupBahan> _grup = [];
  final List<_LangkahForm> _langkah = [];

  static const _kategoriBawaan = [
    'Tradisional',
    'Sarapan',
    'Pedas',
    'Cepat & Mudah',
    'Seafood',
  ];

  /// Satuan sama dengan pilihan di form web.
  static const _satuan = [
    'gram',
    'kg',
    'sdm',
    'sdt',
    'buah',
    'siung',
    'butir',
    'lembar',
    'batang',
    'bungkus',
    'ml',
    'liter',
    'secukupnya',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    final e = widget.existing;
    if (e == null) {
      _grup.add(_GrupBahan()
        ..baris.addAll([
          _BarisBahan(),
          _BarisBahan(),
          _BarisBahan(),
        ]));
      _langkah.add(_LangkahForm());
      return;
    }

    _title.text = e.title;
    _desc.text = e.description;
    _publish = e.isPublished;
    _fotoUrl = e.photoUrl;
    final p = RegExp(r'(\d+)').firstMatch(e.servings ?? '');
    if (p != null) _porsi.text = p.group(1)!;
    if (e.estCostManual != null) _price.text = '${e.estCostManual}';

    _kategori
      ..clear()
      ..addAll(e.kategoriNama.isNotEmpty
          ? e.kategoriNama
          : [e.category == 'Lainnya' ? 'Tradisional' : e.category]);
    _tagTambahan.addAll(_kategori.where((k) => !_kategoriBawaan.contains(k)));

    // Bahan lama: kelompokkan per grup, atau satu grup dari teks utuh.
    final bahan = e.bahanDetail.isNotEmpty
        ? e.bahanDetail
        : e.ingredientsRaw
            .map((t) => RecipeIngredient(nama: t))
            .toList();
    if (bahan.isEmpty) {
      _grup.add(_GrupBahan()..baris.add(_BarisBahan()));
    } else {
      final urutGrup = <String>[];
      final perGrup = <String, List<RecipeIngredient>>{};
      for (final b in bahan) {
        final g = b.grup.trim().isEmpty ? 'Bahan Utama' : b.grup.trim();
        if (!perGrup.containsKey(g)) {
          urutGrup.add(g);
          perGrup[g] = [];
        }
        perGrup[g]!.add(b);
      }
      for (final g in urutGrup) {
        final grup = _GrupBahan(judulAwal: g);
        for (final b in perGrup[g]!) {
          grup.baris.add(_BarisBahan(
            namaAwal: b.nama,
            jumlahAwal: b.jumlah,
            satuan: _satuan.contains(b.satuan) ? b.satuan : 'gram',
          ));
        }
        _grup.add(grup);
      }
    }

    final langkah = e.langkahDetail;
    if (langkah.isEmpty) {
      for (final s in e.stepsList) {
        _langkah.add(_LangkahForm()..teks.text = s);
      }
    } else {
      for (final l in langkah) {
        final f = _LangkahForm()..teks.text = l.instruksi;
        if (l.durasiMenit > 0) f.menit.text = '${l.durasiMenit}';
        if (l.durasiDetik > 0) f.detik.text = '${l.durasiDetik}';
        for (var i = 0; i < l.gambarUrls.length; i++) {
          f.foto.add(_FotoLangkah(
            id: i < l.gambarIds.length ? l.gambarIds[i] : null,
            url: l.gambarUrls[i],
          ));
        }
        _langkah.add(f);
      }
    }
    if (_langkah.isEmpty) _langkah.add(_LangkahForm());
  }

  String get _kategoriUtama =>
      _kategori.isEmpty ? 'Lainnya' : _kategori.first;

  int get _totalMenit {
    var detik = 0;
    for (final l in _langkah) {
      detik += (int.tryParse(l.menit.text.trim()) ?? 0) * 60;
      detik += int.tryParse(l.detik.text.trim()) ?? 0;
    }
    return detik == 0 ? 0 : (detik / 60).ceil();
  }

  /// Kategori server (kalau sudah termuat) + bawaan + tag buatan pengguna.
  List<String> get _daftarKategori {
    final hasil = <String>{
      ...widget.repo.kategori.keys,
      ..._kategoriBawaan,
      ..._tagTambahan,
      ..._kategori,
    };
    return hasil.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sama seperti kartu resep: tanpa unggahan, pakai gambar bawaan aplikasi.
    const preview = fotoResepBawaan;
    final shownTitle =
        _title.text.trim().isEmpty ? 'Judul Masakan Anda' : _title.text.trim();

    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
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
                padding: const EdgeInsets.only(left: 8)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check,
                            size: 14, color: AppColors.chocolate),
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
            _tips(),
            const SizedBox(height: 16),
            _fotoSampul(preview, shownTitle),
            const SizedBox(height: 18),
            _bagianKategori(),
            const SizedBox(height: 16),
            _bagianInfo(),
            const SizedBox(height: 16),
            _bagianPorsiWaktu(),
            const SizedBox(height: 16),
            _bagianBiaya(),
            const SizedBox(height: 20),
            _bagianBahan(),
            const SizedBox(height: 20),
            _bagianLangkah(),
            const SizedBox(height: 8),
            _toggleKomunitas(),
            const SizedBox(height: 16),
            _tombolSimpan(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- Bagian-bagian form ----------

  Widget _tips() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7).withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.soup_kitchen, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fokus Memasak Nyata',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  'Lengkapi takaran bahan, durasi tiap langkah, dan foto proses bila perlu. Tanpa foto sampul, kami pilihkan sesuai kategori. Foto otomatis dikompres agar hemat kuota.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 19.5 / 12,
                      color: AppColors.chocolateMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoSampul(String preview, String shownTitle) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 176,
            width: double.infinity,
            child: _fotoBytes != null
                ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                : AppImage(
                    url: _fotoUrl ?? preview,
                    fallbackLetter: _kategoriUtama,
                  ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3D2314).withValues(alpha: 0.0),
                  const Color(0xFF3D2314).withValues(alpha: 0.2),
                  const Color(0xFF3D2314).withValues(alpha: 0.8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 14, color: AppColors.chocolate),
                const SizedBox(width: 6),
                Text(
                  _fotoBytes != null || _fotoUrl != null
                      ? 'Foto Unggahanmu'
                      : 'Gambar Bawaan Resep',
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
          right: 12,
          top: 12,
          child: GestureDetector(
            onTap: _saving ? null : _pilihFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Foto',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shownTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const Text('Sentuhan bumbu dapur otentik keluarga',
                  style: TextStyle(color: Color(0xFFFFC9B7), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bagianKategori() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text('Kategori & Karakter',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            Text('Bisa pilih lebih dari satu',
                style: TextStyle(
                    fontSize: 11, color: AppColors.chocolateMuted)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._daftarKategori.map((c) {
              final sel = _kategori.contains(c);
              return FilterChip(
                label: Text(c),
                selected: sel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.sand,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.chocolate,
                    fontWeight: FontWeight.w600),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                onSelected: (v) => setState(() {
                  v ? _kategori.add(c) : _kategori.remove(c);
                }),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: Color(0xFF7F2500)),
              label: const Text('Tag Baru',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F2500))),
              backgroundColor: const Color(0xFFFFEAE0),
              shape: const StadiumBorder(),
              side: BorderSide.none,
              onPressed: _tambahTag,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _kategori.isEmpty
              ? 'Belum ada kategori dipilih — foto memakai gambar bawaan.'
              : 'Tanpa unggahan, foto memakai gambar bawaan resep.',
          style: const TextStyle(
              fontSize: 11, color: AppColors.chocolateMuted),
        ),
      ],
    );
  }

  Widget _bagianInfo() {
    return _kartu(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nama Resep', wajib: true),
          const SizedBox(height: 6),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Contoh: Ayam Bakar Bumbu Rujak Mertua'),
          ),
          const SizedBox(height: 16),
          _label('Cerita Resep', opsional: true),
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
    );
  }

  Widget _bagianPorsiWaktu() {
    return Row(
      children: [
        Expanded(
          child: _kotakAngka(
            'Porsi',
            _porsi,
            'orang',
            Icons.group,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kotakTotalWaktu(),
        ),
      ],
    );
  }

  Widget _bagianBiaya() {
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
            children: const [
              Icon(Icons.payments_outlined,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Estimasi Belanja Bahan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Chip(label: Text('±Rp • estimasi sebagian')),
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
              padding: const EdgeInsets.only(top: 6),
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
    );
  }

  Widget _bagianBahan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bahan-Bahan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate)),
                  Text('Takaran, satuan, dan grup persiapan dapur',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.chocolateMuted)),
                ],
              ),
            ),
            _pillTambah(
              'Bahan',
              () => setState(() => _grup.first.baris.add(_BarisBahan())),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var g = 0; g < _grup.length; g++) _grupBahan(g),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _grup.add(
              _GrupBahan(judulAwal: 'Bahan Tambahan ${_grup.length + 1}')
                ..baris.add(_BarisBahan()))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: const Color(0xFFDEC0B7)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.create_new_folder_outlined,
                    size: 16, color: AppColors.chocolate),
                SizedBox(width: 6),
                Text('Buat Grup Bahan Baru',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chocolate)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _grupBahan(int g) {
    final grup = _grup[g];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: grup.judul,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Nama grup bahan...',
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text('${grup.baris.length} item',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.chocolateMuted)),
              if (_grup.length > 1)
                IconButton(
                  tooltip: 'Hapus grup',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => setState(() {
                    _grup.removeAt(g).dispose();
                  }),
                ),
            ],
          ),
          for (var b = 0; b < grup.baris.length; b++) _barisBahan(grup, b),
          TextButton.icon(
            onPressed: () => setState(() => grup.baris.add(_BarisBahan())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Bahan ke Grup Ini',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _barisBahan(_GrupBahan grup, int b) {
    final baris = grup.baris[b];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: baris.nama,
                  decoration: InputDecoration(
                    hintText: 'Nama bahan (misal: bawang merah)',
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus bahan',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: grup.baris.length > 1
                    ? () => setState(() {
                          grup.baris.removeAt(b).dispose();
                        })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: baris.jumlah,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Jumlah',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: baris.satuan,
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.chocolate,
                          fontWeight: FontWeight.w600),
                      items: _satuan
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => baris.satuan = v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bagianLangkah() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Langkah Memasak',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Setiap langkah bisa diberi waktu dan foto proses',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.chocolateMuted)),
                ],
              ),
            ),
            _pillTambah(
              'Langkah',
              () => setState(() => _langkah.add(_LangkahForm())),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _langkah.length; i++) _kartuLangkah(i),
      ],
    );
  }

  Widget _kartuLangkah(int i) {
    final l = _langkah[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primary,
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Hapus langkah',
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _langkah.length > 1
                    ? () => setState(() {
                          _langkah.removeAt(i).dispose();
                        })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: l.teks,
            maxLines: 3,
            decoration: InputDecoration(
                hintText: 'Langkah ${i + 1}...'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              const Text('Waktu:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
              const SizedBox(width: 6),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: l.menit,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText: '0',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                ),
              ),
              const SizedBox(width: 4),
              const Text('mnt',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.chocolateMuted)),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: l.detik,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                      hintText: '0',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                ),
              ),
              const SizedBox(width: 4),
              const Text('dtk',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.chocolateMuted)),
            ],
          ),
          const SizedBox(height: 10),
          _fotoLangkah(l),
        ],
      ),
    );
  }

  Widget _fotoLangkah(_LangkahForm l) {
    return Row(
      children: [
        for (var f = 0; f < l.foto.length; f++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: l.foto[f].bytes != null
                        ? Image.memory(l.foto[f].bytes!, fit: BoxFit.cover)
                        : AppImage(
                            url: l.foto[f].url ?? '',
                            fallbackLetter: 'F',
                          ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => setState(() => l.foto.removeAt(f)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.chocolate,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (l.foto.length < 3)
          GestureDetector(
            onTap: _saving ? null : () => _pilihFotoLangkah(l),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      size: 16, color: AppColors.chocolate),
                  const SizedBox(width: 6),
                  Text('Foto (${l.foto.length}/3)',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chocolate)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _toggleKomunitas() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.lock_open, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terbuka untuk Komunitas',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Resep dapat dicari dan disukai pengguna lain',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.chocolateMuted)),
              ],
            ),
          ),
          Switch(
            value: _publish,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _publish = v),
          ),
        ],
      ),
    );
  }

  Widget _tombolSimpan() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => _save(false),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('Simpan Draf'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : () => _save(_publish),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_saving ? 'Menyimpan...' : 'Terbitkan Resep'),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Helper tampilan ----------

  Widget _kartu(Widget child) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7).withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Widget _label(String teks, {bool wajib = false, bool opsional = false}) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.chocolate),
        children: [
          TextSpan(text: teks),
          if (wajib)
            const TextSpan(
                text: ' *',
                style: TextStyle(
                    fontWeight: FontWeight.w400, color: Color(0xFF7F2500))),
          if (opsional)
            const TextSpan(
                text: ' (Opsional)',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.chocolateMuted)),
        ],
      ),
    );
  }

  Widget _pillTambah(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEAE0),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Color(0xFF7F2500)),
            const SizedBox(width: 4),
            Text('Tambah $label',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7F2500))),
          ],
        ),
      ),
    );
  }

  Widget _kotakAngka(String label, TextEditingController ctrl, String unit,
      IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.secondary),
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
                      fontWeight: FontWeight.w800, fontSize: 16),
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
                      fontSize: 11, color: AppColors.chocolateMuted)),
            ],
          ),
        ],
      ),
    );
  }

  /// Total waktu dihitung dari durasi semua langkah (sama seperti web).
  Widget _kotakTotalWaktu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDEC0B7).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.schedule, size: 14, color: AppColors.secondary),
              SizedBox(width: 4),
              Text('Total Waktu',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_totalMenit',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: 4),
              const Text('menit',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.chocolateMuted)),
            ],
          ),
          const Text('dari durasi langkah',
              style:
                  TextStyle(fontSize: 9, color: AppColors.chocolateMuted)),
        ],
      ),
    );
  }

  // ---------- Aksi ----------

  Future<void> _tambahTag() async {
    final ctrl = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Tag Kategori Baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Contoh: Masakan Sunda'),
          onSubmitted: (v) => Navigator.pop(d, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(d, ctrl.text),
              child: const Text('Tambah')),
        ],
      ),
    );
    final bersih = (nama ?? '').trim();
    ctrl.dispose();
    if (bersih.isEmpty || !mounted) return;
    setState(() {
      _tagTambahan.add(bersih);
      _kategori.add(bersih);
    });
  }

  /// Pilih foto resep (galeri/kamera); sudah dikompres oleh plugin.
  /// Unggahan ke Cloudinary baru dilakukan saat Simpan.
  Future<void> _pilihFoto() async {
    final f = await pilihFoto(context, maxSide: 1280);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoBytes = bytes;
      _gambarId = null;
    });
  }

  Future<void> _pilihFotoLangkah(_LangkahForm l) async {
    final f = await pilihFoto(context, maxSide: 1080);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => l.foto.add(_FotoLangkah(bytes: bytes)));
  }

  int? _priceValue() =>
      int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));

  String _pricePreview() {
    final v = _priceValue() ?? 0;
    final lo = Money.rp((v * 0.75).round());
    final hi = Money.rp((v * 1.25).round());
    return 'Perkiraan $lo - $hi (estimasi)';
  }

  Future<int?> _unggahFotoLangkah(_FotoLangkah f) async {
    if (f.id != null) return f.id;
    if (f.bytes == null) return null;
    final up = await widget.repo.uploadFoto(f.bytes!, filename: 'langkah.jpg');
    f.id = up.id;
    f.url = up.url;
    return up.id;
  }

  Future<void> _save(bool publish) async {
    if (_saving) return;

    final bahan = <RecipeIngredient>[];
    for (final g in _grup) {
      final grup = g.judul.text.trim() == 'Bahan Utama'
          ? ''
          : g.judul.text.trim();
      for (final b in g.baris) {
        final nama = b.nama.text.trim();
        if (nama.isEmpty) continue;
        final cukup = b.satuan == 'secukupnya';
        bahan.add(RecipeIngredient(
          nama: nama,
          jumlah: cukup
              ? (b.jumlah.text.trim().isEmpty
                  ? 'secukupnya'
                  : '${b.jumlah.text.trim()} secukupnya')
              : b.jumlah.text.trim(),
          satuan: cukup ? '' : b.satuan,
          grup: grup,
        ));
      }
    }

    if (_title.text.trim().isEmpty || bahan.isEmpty || _langkah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lengkapi: judul + min 1 bahan + min 1 langkah')));
      return;
    }
    if (_langkah.every((l) => l.teks.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Isi minimal satu instruksi langkah.')));
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

    try {
      if (_fotoBytes != null && _gambarId == null) {
        final up = await widget.repo
            .uploadFoto(_fotoBytes!, filename: 'resep.jpg');
        _gambarId = up.id;
      }

      final langkah = <RecipeStep>[];
      for (final l in _langkah) {
        final teks = l.teks.text.trim();
        if (teks.isEmpty) continue;
        final ids = <int>[];
        for (final f in l.foto) {
          final id = await _unggahFotoLangkah(f);
          if (id != null) ids.add(id);
        }
        langkah.add(RecipeStep(
          instruksi: teks,
          durasiMenit: int.tryParse(l.menit.text.trim()) ?? 0,
          durasiDetik: (int.tryParse(l.detik.text.trim()) ?? 0).clamp(0, 59),
          gambarIds: ids,
        ));
      }

      final porsi = int.tryParse(_porsi.text.trim());
      final manual = _priceValue();
      if (ex == null) {
        await widget.repo.addCustom(
          title: _title.text.trim(),
          kategori: _kategori.toList(),
          bahan: bahan,
          langkah: langkah,
          publish: publish,
          description: _desc.text.trim(),
          porsi: porsi,
          waktuMasak: _totalMenit > 0 ? _totalMenit : null,
          estCostManual: manual,
          gambarUtamaId: _gambarId,
        );
      } else {
        await widget.repo.updateCustom(
          ex.docId,
          title: _title.text.trim(),
          kategori: _kategori.toList(),
          bahan: bahan,
          langkah: langkah,
          publish: publish,
          description: _desc.text.trim(),
          porsi: porsi,
          waktuMasak: _totalMenit > 0 ? _totalMenit : null,
          estCostManual: manual,
          gambarUtamaId: _gambarId,
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
      messenger.showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${_pesan(e)}')));
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
    _controller.dispose();
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _porsi.dispose();
    for (final g in _grup) {
      g.dispose();
    }
    for (final l in _langkah) {
      l.dispose();
    }
    super.dispose();
  }
}
