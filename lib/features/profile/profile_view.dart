import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/food_photos.dart';
import '../../data/recipe_photo.dart';
import '../../data/recipe_repository.dart';
import '../../models/recipe.dart';
import '../detail/detail_view.dart';
import '../notifications/notifications_view.dart';

/// Profil ala Stitch: header lengkung + avatar + stats + tab
/// Resep Saya/Disimpan (kelola: terbitkan/tarik/hapus) + bantuan + logout.
class ProfileScreen extends StatefulWidget {
  final RecipeRepository repo;
  final VoidCallback onLogout;
  const ProfileScreen(
      {super.key, required this.repo, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _mine = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        final mine = widget.repo.customs
            .where((r) => r.ownerId == 'local')
            .toList();
        final saved = widget.repo.favorites;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(mine.length, saved.length),
            _stats(mine.length, saved.length),
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

  Widget _header(int made, int fav) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 24, 20, 56),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('PROFIL CHEF',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: AppImage(
                    url: FoodPhotos.avatar,
                    fallbackLetter:
                        widget.repo.userName,
                  ),
                ),
              ),
              const Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.amber,
                  child: Icon(Icons.verified,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.repo.userName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.repo.userEmail,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(9999),
                  ),
                  child: const Text('SSO',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pencinta kuliner nusantara & eksperimen resep rumahan simpel 🍳',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _stats(int made, int fav) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _stat('$made', 'Resep Dibuat'),
                _stat('$fav', 'Favorit'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String n, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(n,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.chocolateMuted)),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab('Resep Saya', _mine,
              () => setState(() => _mine = true)),
          const SizedBox(width: 8),
          _tab('Disimpan', !_mine,
              () => setState(() => _mine = false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.sand,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
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

  Widget _customRow(Recipe r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                      url: photoFor(r),
                      fallbackLetter: r.title),
                  if (!r.isPublished)
                    const Positioned(
                      left: 2,
                      bottom: 2,
                      child: Chip(
                        label: Text('Draf'),
                        visualDensity:
                            VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ),
          title: Text(r.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              r.isPublished ? 'Publik' : 'Dalam Penulisan'),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle') {
                widget.repo.togglePublish(r.docId);
              } else if (v == 'delete') {
                widget.repo.deleteCustom(r.docId);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'toggle',
                  child: Text(r.isPublished
                      ? 'Tarik ke Draf'
                      : 'Terbitkan')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus')),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(
                    repo: widget.repo, recipe: r)),
          ),
        ),
      ),
    );
  }

  Widget _savedRow(Recipe r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: AppImage(
                  url: photoFor(r),
                  fallbackLetter: r.title),
            ),
          ),
          title: Text(r.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(r.category),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(
                    repo: widget.repo, recipe: r)),
          ),
        ),
      ),
    );
  }

  Widget _settings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferensi & Pengaturan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chocolate)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.sand,
                child: Icon(Icons.notifications_outlined,
                    color: AppColors.primary),
              ),
              title: const Text('Notifikasi',
                  style:
                      TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  widget.repo.unreadCount > 0
                      ? '${widget.repo.unreadCount} belum dibaca'
                      : 'Semua sudah dibaca'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NotificationsScreen(
                        repo: widget.repo)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.sand,
                child: Icon(Icons.help_center,
                    color: AppColors.primary),
              ),
              title: const Text('Bantuan & FAQ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700)),
              subtitle: const Text(
                  'Panduan memasak & lisensi resep'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Bantuan MasakYuk'),
                  content: const Text(
                    '1. Ketik bahan di Home untuk cari resep.\n'
                    '2. Label "estimasi sebagian" = ada bahan tanpa data harga.\n'
                    '3. Resep Draf hanya milikmu; Terbitkan agar orang lain bisa menemukan.\n'
                    '4. Resep seed berasal dari dataset terbuka.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await ConfirmDialog.ask(
                  context,
                  title: 'Keluar dari Akun?',
                  desc:
                      'Kamu harus masuk kembali agar koleksi resep dan favorit tetap tersinkron.',
                  yesLabel: 'Ya, Keluar',
                );
                if (ok) widget.onLogout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar Akun'),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('MasakYuk v1.0 • Edisi Nusantara',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.chocolateMuted)),
          ),
        ],
      ),
    );
  }
}
