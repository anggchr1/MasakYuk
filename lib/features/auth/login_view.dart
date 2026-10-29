import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// Login v2 — ikut Figma "2. Login - MasakYuk v2" (62:373):
/// hero foto + badge melayang, judul, 2 tombol pill, trust row, disclaimer.
/// Tombol Google memakai OAuth yang sama dengan web (lihat AuthProvider).
class LoginScreen extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback onGuest;
  const LoginScreen({super.key, required this.auth, required this.onGuest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, Color(0xFFFFF8F6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Hero: foto rounded 32 + badge melayang.
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE2D5),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.chocolate.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/login_hero.jpg',
                          fit: BoxFit.cover,
                        ),
                        // Vignette hangat bawah.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x1A000000),
                                Color(0x003D2314),
                                Color(0x993D2314),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: AppColors.sand
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '1500+ Resep Nusantara • Mudah',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: AppColors.chocolate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.9',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Konten + tombol.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAE0),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.soup_kitchen,
                              size: 13, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Text(
                            'DAPUR RUMAH IDAMAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.275,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mulai Petualangan Masakmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.65,
                        height: 34 / 26,
                        color: AppColors.chocolate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temukan inspirasi hidangan rumahan lezat, resep praktis, dan bumbu khas Nusantara tanpa ribet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.chocolateMuted,
                      ),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            auth.busy ? null : auth.loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.chocolate,
                          elevation: 2,
                          shadowColor: AppColors.chocolate
                              .withValues(alpha: 0.06),
                          side: const BorderSide(
                              color: Color(0xFFDEC0B7)),
                        ),
                        child: auth.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/google_g.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Masuk dengan Google',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onGuest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 2),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Jelajahi Resep Terlebih Dahulu'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    Container(
                      padding: const EdgeInsets.only(top: 13),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Color(0xFFFFEAE0)),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: AppColors.chocolateMuted),
                          SizedBox(width: 8),
                          Text(
                            'Akses mudah & praktis • Resep asli dapur rumah',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.chocolateMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      const TextSpan(
                        style: TextStyle(
                            fontSize: 12,
                            height: 19.5 / 12,
                            color: AppColors.chocolateMuted),
                        children: [
                          TextSpan(
                              text:
                                  'Dengan melanjutkan, Anda menyetujui '),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: TextStyle(
                              color: AppColors.chocolate,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: '\nserta '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: TextStyle(
                              color: AppColors.chocolate,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' MasakYuk.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
