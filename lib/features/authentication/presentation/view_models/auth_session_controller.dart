import 'dart:async';

import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionState {
  const AuthSessionState({this.isSignedIn = false, this.isRecovering = false});

  final bool isSignedIn;
  final bool isRecovering;
}

final authSessionProvider = NotifierProvider<AuthSessionController, AuthSessionState>(AuthSessionController.new);

class AuthSessionController extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.sessionChanges.listen(
      (event) {
        // Initial events may arrive while the provider is still building.
        scheduleMicrotask(() {
          if (!ref.mounted) return;
          state = AuthSessionState(
            isSignedIn: event != AuthSessionEvent.signedOut,
            isRecovering:
                event == AuthSessionEvent.passwordRecovery ||
                (state.isRecovering && event != AuthSessionEvent.signedOut),
          );
        });
      },
      onError: (Object _) {
        // Explicit sign-out events clear the session; temporary refresh errors do not.
      },
    );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return AuthSessionState(isSignedIn: repository.isSignedIn);
  }

  void beginRecovery() {
    if (ref.mounted) state = AuthSessionState(isSignedIn: state.isSignedIn, isRecovering: true);
  }

  void finishRecovery() {
    if (ref.mounted) state = AuthSessionState(isSignedIn: state.isSignedIn);
  }
}
