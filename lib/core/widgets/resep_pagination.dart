import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Footer daftar resep: "1–N dari total" + tombol muat 100 berikutnya.
class ResepPagination extends StatelessWidget {
  final int tampil;
  final int total;
  final bool memuat;
  final bool habis;
  final VoidCallback onMuatLagi;
  const ResepPagination({
    super.key,
    required this.tampil,
    required this.total,
    required this.memuat,
    required this.habis,
    required this.onMuatLagi,
  });

  @override
  Widget build(BuildContext context) {
    if (tampil == 0 || total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          '1–$tampil dari $total resep',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, color: AppColors.chocolateMuted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: habis || memuat ? null : onMuatLagi,
            child: Text(memuat
                ? 'Memuat 100 resep…'
                : habis
                    ? 'Semua resep sudah tampil'
                    : 'Lihat 100 resep lagi'),
          ),
        ),
      ],
    );
  }
}
