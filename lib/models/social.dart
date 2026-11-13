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

  /// Notifikasi dari GET /api/v1/notifikasi (hanya komentar).
  factory NotifItem.dariServer(Map<String, dynamic> j) => NotifItem(
        id: (j['id'] ?? '').toString(),
        kind: (j['jenis'] ?? 'komentar').toString(),
        title: (j['judul'] ?? '').toString(),
        desc: (j['isi'] ?? '').toString(),
        at: DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal() ??
            DateTime.now(),
        recipeId: j['tipe_terkait'] == 'resep' && j['id_terkait'] != null
            ? j['id_terkait'].toString()
            : null,
        read: j['dibaca'] == true || j['dibaca'] == 1,
      );
}
