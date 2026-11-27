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
    extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    // Ambil notifikasi terbaru tiap layar dibuka.
    widget.repo.muatNotifikasi();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'komentar':
        return const Color(0xFF7F2500);
      case 'rating':
      case 'penilaian':
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
      case 'penilaian':
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
      case 'penilaian':
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
        return FadeTransition(
          opacity: _fade,
          child: Scaffold(
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
                              'Komentar baru di resepmu akan muncul di sini.',
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
        ));
      },
    );
  }

  /// Header coklat melengkung: kembali + judul + tandai semua dibaca.
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifikasi',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.55,
                            color: Colors.white)),
                    Text('Pesan aktivitas resep & dapur',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB59C))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.repo.markAllRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text('Tandai dibaca',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 14, color: Color(0xFFFFB59C)),
              const SizedBox(width: 6),
              Text(
                widget.repo.unreadCount > 0
                    ? '${widget.repo.unreadCount} notifikasi belum dibaca'
                    : 'Semua notifikasi sudah dibaca',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFB59C)),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n.read
            ? AppColors.sand.withValues(alpha: 0.7)
            : AppColors.sand,
        borderRadius: BorderRadius.circular(24),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
                      Expanded(
                        child: Text(
                            timeago.format(n.at,
                                locale: 'id'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors
                                    .chocolateMuted)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _open(n),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(_action(n.kind),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: n.read
                                          ? AppColors
                                              .chocolateMuted
                                          : const Color(
                                              0xFF7F2500))),
                            ),
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
