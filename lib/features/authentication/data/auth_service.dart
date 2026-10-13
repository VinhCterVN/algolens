import 'package:algolens/core/config/supabase_config.dart';
import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/data/auth_session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.client, this.storage);

  final SupabaseClient client;
  final AuthSessionStorage storage;

  String? get _redirect => kIsWeb ? null : SupabaseConfig.redirectUrl;

  Future<void> signIn(String email, String password, bool remember) async {
    await storage.setRemember(remember);
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> register(String name, String email, String password, String role, String experience) async {
    await storage.setRemember(true);
    final response = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _redirect,
      data: {'display_name': name, 'requested_role': role, 'experience_level': experience},
    );
    return response.session != null;
  }

  Future<void> verifyEmail(String email, String code) async {
    await storage.setRemember(true);
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  Future<void> resendConfirmation(String email) async {
    await client.auth.resend(type: OtpType.signup, email: email, emailRedirectTo: _redirect);
  }

  Future<void> sendRecoveryCode(String email) => client.auth.resetPasswordForEmail(email, redirectTo: _redirect);

  Future<void> verifyRecoveryCode(String email, String code) async {
    await storage.setRemember(false);
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
  }

  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signInWithProvider(AuthProvider provider, bool remember) async {
    await storage.setRemember(remember);
    final opened = await client.auth.signInWithOAuth(
      provider == AuthProvider.github ? OAuthProvider.github : OAuthProvider.google,
      redirectTo: _redirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const AuthFailure('Could not open the sign-in provider. Please try again.');
    }
  }

  Future<void> signOut() => client.auth.signOut();
}
