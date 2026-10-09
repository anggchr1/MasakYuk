import 'dart:async';
import 'package:flutter/foundation.dart';

/// State mode memasak: posisi langkah + timer countdown per langkah.
/// Timer murni lokal (tanpa backend) — target awal diturunkan dari teks.
class CookingProvider extends ChangeNotifier {
  final int total;
  CookingProvider(this.total);

  int index = 0;
  int _target = 180;
  int _left = 180;
  Timer? _timer;
  bool running = false;
  final Set<String> boxChecked = {};

  bool get isLast => total == 0 || index >= total - 1;
  double get progress => total == 0 ? 1 : (index + 1) / total;
  int get left => _left;
  String get clock =>
      '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}';
  String get targetLabel => 'Target: ${_target ~/ 60}:00 menit';

  /// Target = ±3 dtk/kata, min 1 mnt, max 10 mnt.
  static int secsFor(String step) {
    final words = step.split(RegExp(r'\s+')).length;
    return (words * 3).clamp(60, 600);
  }

  void retarget(int secs) {
    pause();
    _target = secs.clamp(60, 3600);
    _left = _target;
    notifyListeners();
  }

  void _go(int i) {
    index = i.clamp(0, total - 1);
    pause();
    notifyListeners();
  }

  void next() {
    if (!isLast) _go(index + 1);
  }

  void prev() {
    if (index > 0) _go(index - 1);
  }

  void jumpTo(int i) => _go(i);

  void toggleTimer() {
    running ? pause() : start();
  }

  void start() {
    if (_left <= 0) _left = _target;
    running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left > 0) {
        _left--;
        notifyListeners();
      } else {
        pause();
      }
    });
    notifyListeners();
  }

  void pause() {
    running = false;
    _timer?.cancel();
    notifyListeners();
  }

  void addMinute() {
    _left += 60;
    _target += 60;
    notifyListeners();
  }

  void toggleBox(String item) {
    if (!boxChecked.remove(item)) boxChecked.add(item);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
