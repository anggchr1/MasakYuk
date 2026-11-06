import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom nav modern: 4 kotak area klik equal, bar lebih tinggi & lebar,
/// ikon aktif di lingkaran putih (dengan outline) yang melongok atas bar,
/// teks label tetap diam di bawah, icon diperbesar sedikit saat naik.
class BottomNav extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const List<(IconData icon, String label)> _items = [
    (Icons.home, 'Home'),
    (Icons.edit_note, 'Masak'),
    (Icons.favorite, 'Favorit'),
    (Icons.person, 'Profil'),
  ];

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  Widget build(BuildContext context) {
    final active = widget.index;
    final width = MediaQuery.of(context).size.width - 16;
    final itemWidth = width / 4;

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.chocolate.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 4 kotak area klik equal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) {
              final isActive = i == active;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Icon hanya untuk item nonaktif. Aktif pake lingkaran di atas,
                      // tapi tetap reserve tempat agar teks rata dengan item lain.
                      if (isActive)
                        const SizedBox(width: 24, height: 24)
                      else
                        Icon(
                          BottomNav._items[i].$1,
                          size: 24,
                          color: AppColors.chocolate.withValues(alpha: 0.45),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        BottomNav._items[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.chocolateMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Lingkaran aktif melongok atas bar, ditempatkan tepat di atas item aktif.
          Positioned(
            top: -16,
            left: itemWidth * active + itemWidth / 2 - 22,
            child: GestureDetector(
              onTap: () => widget.onTap(active),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 1.1,
                    child: Icon(
                      BottomNav._items[active].$1,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
