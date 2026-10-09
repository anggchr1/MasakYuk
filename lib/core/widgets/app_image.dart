import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gambar network ala Stitch dengan fallback monogram terracotta.
/// Hotlink Stitch bisa mati sewaktu-waktu — UI tidak boleh ikut mati.
class AppImage extends StatelessWidget {
  final String url;
  final String fallbackLetter;
  final BoxFit fit;
  const AppImage({
    super.key,
    required this.url,
    required this.fallbackLetter,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final letter =
        fallbackLetter.isEmpty ? '?' : fallbackLetter[0].toUpperCase();
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.sand,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
      errorBuilder: (_, _, _) => Container(
        color: AppColors.primaryContainer,
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
