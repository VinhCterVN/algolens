import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthFormViewModel extends ChangeNotifier {
  bool busy = false;
  String? error;
  String? message;
  bool _disposed = false;

  Future<bool> run(Future<void> Function() action, {String? successMessage}) async {
    if (busy) return false;
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      await action();
      message = successMessage;
      return true;
    } on AuthFailure catch (failure) {
      error = failure.message;
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
