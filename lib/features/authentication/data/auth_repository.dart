enum AuthSessionEvent { signedIn, signedOut, passwordRecovery }

enum AuthProvider { github, google }

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

abstract class AuthRepository {
  bool get isSignedIn;

  Stream<AuthSessionEvent> get sessionChanges;

  Future<void> signIn(String email, String password, {required bool remember});

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String requestedRole,
    required String experience,
  });

  Future<void> verifyEmail(String email, String code);

  Future<void> resendConfirmation(String email);

  Future<void> sendRecoveryCode(String email);

  Future<void> verifyRecoveryCode(String email, String code);

  Future<void> updatePassword(String password);

  Future<void> signInWithProvider(AuthProvider provider, {bool remember = true});

  Future<void> signOut();
}

// Screens remain previewable before project configuration, but never fake a session.
class UnconfiguredAuthRepository extends AuthRepository {
  @override
  bool get isSignedIn => false;

  @override
  Stream<AuthSessionEvent> get sessionChanges => const Stream.empty();

  Never _unavailable() => throw const AuthFailure('Authentication is unavailable right now. Please try again later.');

  @override
  Future<void> signIn(String email, String password, {required bool remember}) async => _unavailable();

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String requestedRole,
    required String experience,
  }) async => _unavailable();

  @override
  Future<void> verifyEmail(String email, String code) async => _unavailable();

  @override
  Future<void> resendConfirmation(String email) async => _unavailable();

  @override
  Future<void> sendRecoveryCode(String email) async => _unavailable();

  @override
  Future<void> verifyRecoveryCode(String email, String code) async => _unavailable();

  @override
  Future<void> updatePassword(String password) async => _unavailable();

  @override
  Future<void> signInWithProvider(AuthProvider provider, {bool remember = true}) async => _unavailable();

  @override
  Future<void> signOut() async => _unavailable();
}
