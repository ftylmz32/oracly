/// OR-1000 — Base controller for Tarot feature state.
library;

import 'package:flutter/foundation.dart';

/// Shared loading / error handling for Tarot controllers.
abstract class TarotBaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  @protected
  set isLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @protected
  set errorMessage(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  @protected
  void clearError() => errorMessage = null;
}
