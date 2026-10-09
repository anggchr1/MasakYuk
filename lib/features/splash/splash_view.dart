import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Splash ala Stitch: logo + progress + status + versi. ~2,4 dtk lalu onDone.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _texts = [
    'Menyiapkan bumbu dapur...',
    'Memanaskan wajan...',
    'Menghitung gizi resep...',
  ];
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _texts.length);
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.soup_kitchen,
                        size: 44, color: Colors.white),
                  ),
                  const Positioned(
                    top: 10,
                    right: 14,
                    child: Icon(Icons.star,
                        size: 14, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: 'Masak',
                        style:
                            TextStyle(color: AppColors.chocolate)),
                    TextSpan(
                        text: 'Yuk',
                        style:
                            TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const Text('RESEP PINTAR & ASISTEN AI',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chocolateMuted)),
              const SizedBox(height: 24),
              const Text(
                'Ubah stok bahan di kulkasmu menjadi hidangan istimewa keluarga setiap hari.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.chocolateMuted),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 2400),
                builder: (_, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: AppColors.sand,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _texts[_i],
                  key: ValueKey(_i),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chocolateMuted),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                        radius: 4,
                        backgroundColor:
                            AppColors.primary),
                    SizedBox(width: 6),
                    Text('Versi 1.0.0 • Ditenagai AI Gemini',
                        style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text('© 2025 MasakYuk.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.chocolateMuted)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}
