import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionStorage extends LocalStorage {
  AuthSessionStorage({required this.projectHost, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final String projectHost;
  final FlutterSecureStorage _storage;
  bool _remember = true;
  DateTime? _expiresAt;

  String get _sessionKey => 'algolens.$projectHost.session';

  String get _expiryKey => 'algolens.$projectHost.remember_until';

  @override
  Future<void> initialize() async {
    final expiry = await _storage.read(key: _expiryKey);
    _expiresAt = DateTime.tryParse(expiry ?? '');
    if (_expiresAt == null || DateTime.now().isAfter(_expiresAt!)) {
      await removePersistedSession();
    }
  }

  Future<void> setRemember(bool remember) async {
    _remember = remember;
    _expiresAt = remember ? DateTime.now().add(const Duration(days: 30)) : null;
    if (remember) {
      await _storage.write(key: _expiryKey, value: _expiresAt!.toIso8601String());
    } else {
      await removePersistedSession();
    }
  }

  @override
  Future<String?> accessToken() async {
    if (!_remember || _expiresAt == null || DateTime.now().isAfter(_expiresAt!)) {
      return null;
    }
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (!_remember || _expiresAt == null) return;
    await _storage.write(key: _sessionKey, value: persistSessionString);
    if (!_remember) await removePersistedSession();
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _expiryKey);
  }
}
