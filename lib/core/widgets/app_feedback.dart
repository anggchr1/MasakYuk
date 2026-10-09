import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kit umpan-balik ala Stitch (icon asset & status dialog):
/// toast gelap, dialog konfirmasi, dan status kosong/gagal.
/// Semua yang tadinya SnackBar mentah / teks polos pindah ke sini.
class AppToast {
  /// Bar gelap + tombol aksi (cth: "Resep Disimpan! ... Lihat").
  static void show(
    BuildContext context,
    String title,
    String desc, {
    IconData icon = Icons.check_circle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.chocolate,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70)),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Text(actionLabel,
                    style: const TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi ala Stitch (cth: "Keluar dari Akun? Ya/Tidak").
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String desc;
  final String yesLabel;
  final String noLabel;
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.desc,
    this.yesLabel = 'Ya',
    this.noLabel = 'Tidak, Batal',
  });

  static Future<bool> ask(
    BuildContext context, {
    required String title,
    required String desc,
    String yesLabel = 'Ya',
    String noLabel = 'Tidak, Batal',
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
          title: title,
          desc: desc,
          yesLabel: yesLabel,
          noLabel: noLabel),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            child: const Icon(Icons.logout,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.chocolate)),
          const SizedBox(height: 8),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.chocolateMuted)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sand,
                    foregroundColor: AppColors.chocolate,
                    elevation: 0,
                  ),
                  child: Text(noLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: Text(yesLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status kosong/gagal/loading ala Stitch (icon + judul + deskripsi).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool loading;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(24),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        strokeWidth: 3),
                  )
                : Icon(icon,
                    size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.chocolate)),
          const SizedBox(height: 4),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.chocolateMuted)),
        ],
      ),
    );
  }
}
