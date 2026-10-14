import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/recipe_repository.dart';
import '../../models/social.dart';
import '../detail/detail_view.dart';
import '../encyclopedia/encyclopedia_view.dart';

/// Inbox ala Stitch: tab + grup Hari ini/Kemarin + aksi per jenis.
class NotificationsScreen extends StatefulWidget {
  final RecipeRepository repo;
  const NotificationsScreen({super.key, required this.repo});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  Color _kindColor(String kind) {
    switch (kind) {
      case 'komentar':
        return const Color(0xFF7F2500);
      case 'rating':
        return AppColors.secondary;
      default:
        return AppColors.amber;
    }
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'komentar':
        return Icons.chat_bubble_outline;
      case 'rating':
        return Icons.star_border;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _action(String kind) {
    switch (kind) {
      case 'komentar':
        return 'Lihat Komentar';
      case 'rating':
        return 'Buka Resep';
      default:
        return 'Buka';
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _open(NotifItem n) {
    widget.repo.markRead(n.id);
    final r = n.recipeId == null
        ? null
        : widget.repo.findById(n.recipeId!);
    if (r != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                DetailScreen(repo: widget.repo, recipe: r)),
      );
    } else if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                EncyclopediaScreen(repo: widget.repo)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        final all = _unreadOnly
            ? widget.repo.notifs
                .where((n) => !n.read)
                .toList()
            : widget.repo.notifs;
        final now = DateTime.now();
        final today = all
            .where((n) => _sameDay(n.at, now))
            .toList();
        final yesterday = all
            .where((n) => _sameDay(
                n.at, now.subtract(const Duration(days: 1))))
            .toList();
        final older = all
            .where((n) =>
                !_sameDay(n.at, now) &&
                !_sameDay(
                    n.at, now.subtract(const Duration(days: 1))))
            .toList();
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tab(
                              'Semua', !_unreadOnly,
                              () => setState(() =>
                                  _unreadOnly = false),
                              null),
                          const SizedBox(width: 8),
                          _tab(
                              'Belum Dibaca', _unreadOnly,
                              () => setState(() =>
                                  _unreadOnly = true),
                              widget.repo.unreadCount),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (all.isEmpty)
                        const EmptyState(
                          icon:
                              Icons.notifications_none,
                          title:
                              'Belum ada notifikasi',
                          desc:
                              'Komentar dan rating di resepmu akan muncul di sini.',
                        )
                      else ...[
                        ..._group(
                            'HARI INI', today, true),
                        ..._group(
                            'KEMARIN', yesterday, false),
                        ..._group('LEBIH LAMA', older,
                            false),
                        _infoBox(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Header krem ala Figma: kembali + judul + tandai dibaca.
  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D3D2314),
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius:
                    BorderRadius.circular(9999),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18,
                  color: AppColors.chocolate),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('Notifikasi',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.chocolate)),
                Text('Pesan aktivitas resep & dapur',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors
                            .chocolateMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.repo.markAllRead,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2D5)
                    .withValues(alpha: 0.6),
                borderRadius:
                    BorderRadius.circular(9999),
              ),
              child: const Text('Tandai Semua\nDibaca',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F2500))),
            ),
          ),
        ],
      ),
      ),
    );
  }

  List<Widget> _group(
      String label, List<NotifItem> items, bool newest) {
    if (items.isEmpty) return [];
    return [
      Padding(
        padding:
            const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.chocolateMuted)),
            const Spacer(),
            if (newest)
              const Text('Terbaru',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.chocolateMuted)),
          ],
        ),
      ),
      ...items.map(_card),
    ];
  }

  Widget _card(NotifItem n) {
    final accent = _kindColor(n.kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: n.read
            ? AppColors.sand.withValues(alpha: 0.7)
            : AppColors.sand,
        borderRadius: BorderRadius.circular(32),
        border: n.read
            ? null
            : Border(
                left: BorderSide(
                    color: accent, width: 4),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: n.read
                  ? const Color(0xFFFFE2D5)
                  : accent,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(n.kind),
                size: 20,
                color: n.read
                    ? AppColors.primary
                    : Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.chocolate)),
                    ),
                    if (!n.read)
                      Container(
                        width: 10,
                        height: 10,
                        decoration:
                            const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(n.desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.chocolateMuted)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.only(top: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color:
                              const Color(0xFFDEC0B7)
                                  .withValues(
                                      alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                          timeago.format(n.at,
                              locale: 'id'),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors
                                  .chocolateMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _open(n),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(_action(n.kind),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: n.read
                                        ? AppColors
                                            .chocolateMuted
                                        : const Color(
                                            0xFF7F2500))),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 12,
                                color: n.read
                                    ? AppColors
                                        .chocolateMuted
                                    : const Color(
                                        0xFF7F2500)),
                          ],
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
    );
  }

  Widget _infoBox() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EB),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: const Color(0xFFDEC0B7)
                .withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Semua interaksi resep berbasis komunitas rumahan asli tanpa metrik buatan. Estimasi harga bersifat acuan perkiraan pasar lokal (±estimasi).',
              style: TextStyle(
                  fontSize: 12,
                  height: 19.5 / 12,
                  color: AppColors.chocolateMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
      String label, bool active, VoidCallback onTap, int? badge) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : AppColors.sand,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: active
                        ? Colors.white
                        : AppColors.chocolate)),
            if (badge != null && badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF7F2500)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
