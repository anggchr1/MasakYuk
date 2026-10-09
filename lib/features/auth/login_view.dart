import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';

/// FR-01 Login ala Stitch: logo + hero foto + Google + tamu.
/// NANTI M2: google_sign_in + FirebaseAuth (tombol sudah pada tempatnya).
class LoginScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onGuest;
  const LoginScreen(
      {super.key, required this.onLogin, required this.onGuest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blur hangat
            const Positioned(
              top: -48,
              right: -48,
              child: _BlurDot(color: AppColors.primary, size: 190),
            ),
            const Positioned(
              top: 220,
              left: -64,
              child: _BlurDot(color: AppColors.amber, size: 160),
            ),
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 24),
                // Logo + nama
                Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.soup_kitchen,
                              size: 40, color: Colors.white),
                        ),
                        const Positioned(
                          bottom: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.amber,
                            child: Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(
                              text: 'Masak',
                              style: TextStyle(
                                  color: AppColors.primary)),
                          TextSpan(
                              text: 'Yuk',
                              style:
                                  TextStyle(color: AppColors.amber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Temukan Resep Lezat dari Bahan di Kulkasmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.chocolateMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Hero foto + badge melayang
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: SizedBox(
                        height: 224,
                        width: double.infinity,
                        child: AppImage(
                          url: FoodPhotos.loginHero,
                          fallbackLetter: 'M',
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.sand.withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(9999),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: AppColors.primary,
                                size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1500+ Resep Nusantara',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ),
                            Chip(
                              label: Text('Mudah'),
                              padding: EdgeInsets.zero,
                              visualDensity:
                                  VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tombol Google putih
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.chocolate,
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('G',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4285F4))),
                        SizedBox(width: 12),
                        Text('Masuk dengan Google',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sand,
                      foregroundColor: AppColors.chocolate,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.restaurant_menu,
                        color: AppColors.primary),
                    label: const Text(
                        'Jelajahi Resep Terlebih Dahulu'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan serta Kebijakan Privasi MasakYuk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.chocolateMuted),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurDot extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}
