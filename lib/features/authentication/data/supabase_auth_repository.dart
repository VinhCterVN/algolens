import 'dart:async';

import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._service);

  final AuthService _service;

  @override
  bool get isSignedIn => _service.client.auth.currentSession != null;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _service.client.auth.onAuthStateChange.map((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      // Recovery sessions should not restore as ordinary sign-ins after restart.
      unawaited(_service.storage.setRemember(false).catchError((Object _) {}));
      return AuthSessionEvent.passwordRecovery;
    }
    return state.session == null ? AuthSessionEvent.signedOut : AuthSessionEvent.signedIn;
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      final message = switch (error.code) {
        'invalid_credentials' || 'invalid_login_credentials' => 'Email or password is incorrect.',
        'email_not_confirmed' => 'Please confirm your email before signing in.',
        'user_already_exists' || 'email_exists' => 'An account already exists for this email. Try signing in.',
        'weak_password' => 'Choose a stronger password with at least 8 characters, a number, and a symbol.',
        'otp_expired' => 'This code is invalid or expired. Request a new one.',
        'over_email_send_rate_limit' || 'over_request_rate_limit' => 'Too many requests. Wait a moment and try again.',
        'provider_disabled' => 'This sign-in provider is not available yet. Use email and password.',
        _ => 'Authentication could not be completed. Check your details and try again.',
      };
      throw AuthFailure(message);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not connect. Check your connection and try again.');
    }
  }

  @override
  Future<void> signIn(String email, String password, {required bool remember}) =>
      _guard(() => _service.signIn(email.trim(), password, remember));

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String requestedRole,
    required String experience,
  }) => _guard(() => _service.register(name.trim(), email.trim(), password, requestedRole, experience));

  @override
  Future<void> verifyEmail(String email, String code) => _guard(() => _service.verifyEmail(email.trim(), code));

  @override
  Future<void> resendConfirmation(String email) => _guard(() => _service.resendConfirmation(email.trim()));

  @override
  Future<void> sendRecoveryCode(String email) => _guard(() => _service.sendRecoveryCode(email.trim()));

  @override
  Future<void> verifyRecoveryCode(String email, String code) =>
      _guard(() => _service.verifyRecoveryCode(email.trim(), code));

  @override
  Future<void> updatePassword(String password) => _guard(() => _service.updatePassword(password));

  @override
  Future<void> signInWithProvider(AuthProvider provider, {bool remember = true}) =>
      _guard(() => _service.signInWithProvider(provider, remember));

  @override
  Future<void> signOut() => _guard(_service.signOut);
}
