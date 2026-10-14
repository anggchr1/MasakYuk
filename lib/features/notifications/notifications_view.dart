import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../data/recipe_repository.dart';
import '../detail/detail_view.dart';

/// Inbox notifikasi: Semua/Belum dibaca + tandai baca + lompat ke resep.
/// Sumber: komentar/rating/publish (lokal dulu, FCM belakangan).
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repo,
      builder: (_, _) {
        final items = _unreadOnly
            ? widget.repo.notifs
                .where((n) => !n.read)
                .toList()
            : widget.repo.notifs;
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifikasi'),
                Text('Pesan aktivitas resep & dapur',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: widget.repo.markAllRead,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white),
                child: const Text('Tandai Semua\nDibaca',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _tab('Semua', !_unreadOnly,
                      () => setState(() => _unreadOnly = false),
                      null),
                  const SizedBox(width: 8),
                  _tab(
                      'Belum Dibaca', _unreadOnly,
                      () => setState(() => _unreadOnly = true),
                      widget.repo.unreadCount),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.notifications_none,
                  title: _unreadOnly
                      ? 'Semua sudah dibaca'
                      : 'Belum ada notifikasi',
                  desc: 'Komentar dan rating di resepmu akan muncul di sini.',
                )
              else
                ...items.map((n) => Card(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.read
                              ? AppColors.sand
                              : AppColors.primary,
                          child: Icon(_icon(n.kind),
                              color: n.read
                                  ? AppColors.primary
                                  : Colors.white),
                        ),
                        title: Text(n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(n.desc,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                                timeago.format(n.at,
                                    locale: 'id'),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors
                                        .chocolateMuted)),
                          ],
                        ),
                        trailing: n.read
                            ? null
                            : const CircleAvatar(
                                radius: 5,
                                backgroundColor:
                                    AppColors.primary),
                        onTap: () {
                          widget.repo.markRead(n.id);
                          final r = n.recipeId == null
                              ? null
                              : widget.repo
                                  .findById(n.recipeId!);
                          if (r != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(
                                          repo:
                                              widget.repo,
                                          recipe: r)),
                            );
                          }
                        },
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _tab(
      String label, bool active, VoidCallback onTap, int? badge) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
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
                    fontSize: 13,
                    color: active
                        ? Colors.white
                        : AppColors.chocolate)),
            if (badge != null && badge > 0) ...[
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 10,
                backgroundColor: active
                    ? Colors.white
                    : AppColors.primary,
                child: Text('$badge',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? AppColors.primary
                            : Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
