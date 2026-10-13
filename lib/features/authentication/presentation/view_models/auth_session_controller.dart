import 'dart:async';

import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController(this.repository) : isSignedIn = repository.isSignedIn {
    _subscription = repository.sessionChanges.listen(
      (event) {
        isSignedIn = event != AuthSessionEvent.signedOut;
        if (event == AuthSessionEvent.passwordRecovery) isRecovering = true;
        if (event == AuthSessionEvent.signedOut) isRecovering = false;
        notifyListeners();
      },
      onError: (Object error) {
        notifyListeners();
      },
    );
  }

  final AuthRepository repository;
  late final StreamSubscription<AuthSessionEvent> _subscription;
  bool isSignedIn;
  bool isRecovering = false;

  void beginRecovery() {
    isRecovering = true;
    notifyListeners();
  }

  void finishRecovery() {
    isRecovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
