import 'package:flutter/material.dart';

class ScrollControlProvider extends ChangeNotifier {
  bool _isBottomNavVisible = true;

  bool get isBottomNavVisible => _isBottomNavVisible;

  void setBottomNavVisibility(bool visible) {
    if (_isBottomNavVisible != visible) {
      _isBottomNavVisible = visible;
      notifyListeners();
    }
  }

  void showBottomNav() => setBottomNavVisibility(true);
  void hideBottomNav() => setBottomNavVisibility(false);
}
