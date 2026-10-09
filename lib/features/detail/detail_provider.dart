import 'package:flutter/foundation.dart';

/// State checklist bahan di Detail (coret saat dicentang).
class DetailProvider extends ChangeNotifier {
  final Set<int> checked = {};

  void toggle(int i) {
    if (!checked.remove(i)) checked.add(i);
    notifyListeners();
  }
}
