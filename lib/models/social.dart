/// Komentar, rating, notifikasi — in-memory (backend MySQL belakangan).
/// Aturan ikut PRD v1.0 teman: rating 1 user 1 aktif per resep (ubah = update).
class CommentItem {
  final String user;
  final String text;
  final DateTime at;
  const CommentItem(
      {required this.user, required this.text, required this.at});
}

class NotifItem {
  final String id;
  final String kind; // komentar | rating | sistem
  final String title;
  final String desc;
  final DateTime at;
  final String? recipeId;
  bool read;
  NotifItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.desc,
    required this.at,
    this.recipeId,
    this.read = false,
  });
}
