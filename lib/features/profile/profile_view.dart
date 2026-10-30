import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../data/food_photos.dart';
import '../../data/money.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../notifications/notifications_view.dart';
import '../recipe_form/add_recipe_view.dart';

/// Profil Figma: header horizontal + 3 stats + tab berhitung +
/// kelola (tarik/ubah/hapus) + pengaturan + versi.
class ProfileScreen extends StatefulWidget {
  final RecipeRepository repo;
  final VoidCallback onLogout;
  final bool isGuest;
  final VoidCallback? onLogin;
  const ProfileScreen(
      {super.key,
      required this.repo,
      required this.onLogout,
      this.isGuest = false,
      this.onLogin});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _mine = true;
  bool _autoClean = false;

  int get _made => widget.repo.customs.length;
  int get _saved => widget.repo.favorites.length;
  int get _liked => widget.repo.customs
      .fold<int>(0, (a, r) => a + r.loves);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        final mine = widget.repo.customs;
        final saved = widget.repo.favorites;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(),
            _stats(),
            _tabs(),
            if (_mine) ...[
              _sectionTitle('Koleksi Terbitan', mine.length),
              ...mine.map(_customRow),
              if (mine.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada resep buatanmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.chocolateMuted),
                  ),
                ),
            ] else ...[
              _sectionTitle('Disimpan', saved.length),
              ...saved.map(_savedRow),
              if (saved.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada yang disimpan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.chocolateMuted),
                  ),
                ),
            ],
            _settings(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 12, 20, 56),
      decoration: const BoxDecoration(
        color: Color(0xFF7F2500),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Halo MasakMania',
                  style: TextStyle(
                      color: Color(0xFFFFB59C),
                      fontSize: 12,
                      letterSpacing: 0.3)),
              const Spacer(),
              CircleAvatar(
                backgroundColor: Colors.white
                    .withValues(alpha: 0.1),
                child: IconButton(
                  icon: const Icon(Icons.help_outline,
                      color: Colors.white, size: 20),
                  onPressed: _help,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white
                    .withValues(alpha: 0.1),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 20),
                  onPressed: _help,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Profil Koki',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.55)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.3),
                          width: 4),
                    ),
                    child: ClipOval(
                      child: AppImage(
                        url: FoodPhotos.avatar,
                        fallbackLetter:
                            widget.repo.userName,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                const Color(0xFF7F2500),
                            width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 14,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              widget.repo.userName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 16, color: Colors.white),
                      ],
                    ),
                    Text(widget.repo.userEmail,
                        style: const TextStyle(
                            color: Color(0xFFFFB59C),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text(
                      'Pencinta masakan rumahan Nusantara. Selalu sedia ulekan batu, terasi bakar, dan daun salam di dapur!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Color(0xFFFFC9B7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 17, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFDEC0B7)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              _stat('$_made', 'Resep Dibuat',
                  const Color(0xFF7F2500), true),
              _stat('$_saved', 'Disimpan',
                  AppColors.chocolateMuted, true),
              _stat('$_liked', 'Disukai',
                  AppColors.primary, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
      String n, String label, Color nColor, bool divider) {
    return Expanded(
      child: Container(
        decoration: divider
            ? BoxDecoration(
                border: Border(
                  right: BorderSide(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.4)),
                ),
              )
            : null,
        child: Column(
          children: [
            Text(n,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: nColor)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.chocolateMuted)),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          children: [
            _tab(
                'Resep Saya ($_made)', _mine,
                () => setState(() => _mine = true)),
            const SizedBox(width: 4),
            _tab(
                'Disimpan ($_saved)', !_mine,
                () => setState(() => _mine = false)),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: active
                  ? Colors.white
                  : AppColors.chocolate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, int n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text('$t ($n)',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.chocolate)),
    );
  }

  /// Kartu horizontal ala Figma: thumb 96 + badge status + meta + harga.
  Widget _rowCard({
    required Recipe r,
    required Widget? trailing,
    required VoidCallback onTap,
    String? priceText,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFDEC0B7)
                    .withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: AppImage(
                          url: photoFor(r),
                          fallbackLetter: r.title),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2),
                      decoration: BoxDecoration(
                        color: r.isPublished
                            ? const Color(0xFF7F2500)
                            : const Color(0xFF605B54),
                        borderRadius:
                            BorderRadius.circular(9999),
                      ),
                      child: Text(
                        r.isPublished
                            ? 'Publik'
                            : 'Draf',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.chocolate)),
                    Text(
                        r.description.isEmpty
                            ? r.category
                            : r.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors
                                .chocolateMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDBCA)
                                .withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color:
                                      AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(r.displayDuration,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: AppColors
                                          .secondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    9999),
                            border: Border.all(
                                color: const Color(
                                        0xFFDEC0B7)
                                    .withValues(
                                        alpha: 0.4)),
                          ),
                          child: Text(
                              r.displayDifficulty,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: AppColors
                                      .chocolateMuted)),
                        ),
                      ],
                    ),
                    if (priceText != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 4),
                        child: Text(priceText,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w700,
                                letterSpacing: 0.5,
                                color:
                                    AppColors.secondary)),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  String? _priceText(Recipe r) {
    final e = widget.repo.estCost(r);
    if (!e.complete) return null;
    final mid = (e.min + e.max) ~/ 2;
    return '±${Money.rp(mid)} • estimasi';
  }

  Widget _customRow(Recipe r) {
    return _rowCard(
      r: r,
      priceText: _priceText(r),
      trailing: PopupMenuButton<String>(
        iconSize: 20,
        padding: EdgeInsets.zero,
        onSelected: (v) async {
          try {
            if (v == 'toggle') {
              await widget.repo.togglePublish(r.docId);
            } else if (v == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddRecipeScreen(
                        repo: widget.repo,
                        existing: r,
                        onNeedLogin: widget.onLogout)),
              );
            } else if (v == 'delete') {
              await widget.repo.deleteCustom(r.docId);
            }
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Gagal menyimpan perubahan.')));
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
              value: 'toggle',
              child: Text(r.isPublished
                  ? 'Tarik Draf'
                  : 'Terbitkan Resep')),
          const PopupMenuItem(
              value: 'edit',
              child: Text('Ubah Resep')),
          const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus Resep')),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DetailScreen(
                repo: widget.repo, recipe: r)),
      ),
    );
  }

  Widget _savedRow(Recipe r) {
    return _rowCard(
      r: r,
      priceText: _priceText(r),
      trailing: null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DetailScreen(
                repo: widget.repo, recipe: r)),
      ),
    );
  }

  Widget _settings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan Akun & Bantuan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chocolate)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFFDEC0B7)
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _menuItem(
                  icon: Icons.help_center,
                  title: 'Bantuan & FAQ',
                  desc:
                      'Panduan memasak, tips takaran, dan info harga estimasi',
                  onTap: _help,
                  divider: true,
                ),
                _menuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Pengaturan Notifikasi',
                  desc:
                      'Pengingat masak sarapan & inspirasi menu harian',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(
                                repo: widget.repo)),
                  ),
                  divider: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEAE0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.cleaning_services,
                            size: 17,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Pembersihan Draf Otomatis',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700)),
                            Text(
                                'Simpan offline cadangan resep dapur lokal',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors
                                        .chocolateMuted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoClean,
                        activeThumbColor:
                            AppColors.primary,
                        onChanged: (v) async {
                          setState(
                              () => _autoClean = v);
                          if (v) {
                            final n = await widget.repo
                                .purgeOldDrafts(30);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                    content: Text(n > 0
                                        ? '$n draf lama dibersihkan.'
                                        : 'Tidak ada draf lama. Pembersihan aktif.')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (widget.isGuest) {
                  widget.onLogin?.call();
                  return;
                }
                final ok = await ConfirmDialog.ask(
                  context,
                  title: 'Keluar dari Akun?',
                  desc:
                      'Kamu harus masuk kembali agar koleksi resep dan favorit tetap tersinkron.',
                  yesLabel: 'Ya, Keluar',
                );
                if (ok) widget.onLogout();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: widget.isGuest
                    ? AppColors.sand
                    : const Color(0xFFFFDAD6)
                        .withValues(alpha: 0.6),
                foregroundColor: widget.isGuest
                    ? AppColors.primary
                    : const Color(0xFF93000A),
                side: BorderSide(
                    color: widget.isGuest
                        ? AppColors.primary
                        : const Color(0xFFBA1A1A)
                            .withValues(alpha: 0.2)),
                shape: const StadiumBorder(),
                minimumSize:
                    const Size.fromHeight(52),
              ),
              icon: Icon(widget.isGuest
                  ? Icons.login
                  : Icons.logout),
              label: Text(
                  widget.isGuest ? 'Masuk' : 'Keluar Akun',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                Text('MasakYuk v2.0.0 (Warm Spice)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors.chocolateMuted)),
                Text(
                    'Dapur Nusantara • Data Jujur & Tanpa Algoritma Rumit',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chocolateMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool divider = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: divider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: const Color(0xFFDEC0B7)
                          .withValues(alpha: 0.2)),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEAE0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 17,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors
                              .chocolateMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16,
                color: AppColors.chocolateMuted),
          ],
        ),
      ),
    );
  }

  void _help() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        title: const Text('Bantuan & FAQ'),
        content: const Text(
          '1. Ketik bahan di Home untuk cari resep.\n'
          '2. Label "estimasi sebagian" = ada bahan tanpa data harga.\n'
          '3. Resep Draf hanya milikmu; Terbitkan agar orang lain bisa menemukan.\n'
          '4. Resep seed berasal dari dataset terbuka (Cookpad).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
