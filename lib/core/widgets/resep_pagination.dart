import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Footer daftar resep: "1–N dari total" + tombol muat 100 berikutnya.
class ResepPagination extends StatelessWidget {
  final int tampil;
  final int total;
  final bool memuat;
  final bool habis;
  final VoidCallback onMuatLagi;
  /// Kata benda yang dihitung, mis. 'resep' atau 'bahan'.
  final String kata;
  const ResepPagination({
    super.key,
    required this.tampil,
    required this.total,
    required this.memuat,
    required this.habis,
    required this.onMuatLagi,
    this.kata = 'resep',
  });

  @override
  Widget build(BuildContext context) {
    if (tampil == 0 || total <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          '1–$tampil dari $total $kata',
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
            child: memuat
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Memuat $kata…'),
                    ],
                  )
                : Text(habis
                    ? 'Semua $kata sudah tampil'
                    : 'Lihat $kata lagi'),
          ),
        ),
      ],
    );
  }
}
