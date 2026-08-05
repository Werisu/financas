import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SavedLoginProvider { email, google }

class SavedLogin {
  const SavedLogin({
    required this.provider,
    required this.email,
    this.password,
  });

  final SavedLoginProvider provider;
  final String email;
  final String? password;

  bool get canBiometricSignIn =>
      provider == SavedLoginProvider.google ||
      (provider == SavedLoginProvider.email &&
          password != null &&
          password!.isNotEmpty);
}

class SavedLoginService {
  SavedLoginService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _providerKey = 'saved_login_provider';
  static const _emailKey = 'saved_login_email';
  static const _passwordKey = 'saved_login_password';

  final FlutterSecureStorage _storage;

  /// Login salvo é só para celular (biometria). Na web não persiste credenciais.
  bool get isSupported => !kIsWeb;

  Future<SavedLogin?> read() async {
    if (!isSupported) return null;
    final providerRaw = await _storage.read(key: _providerKey);
    final email = await _storage.read(key: _emailKey);
    if (providerRaw == null || email == null || email.isEmpty) return null;

    final provider = providerRaw == SavedLoginProvider.google.name
        ? SavedLoginProvider.google
        : SavedLoginProvider.email;
    final password = await _storage.read(key: _passwordKey);

    final login = SavedLogin(
      provider: provider,
      email: email,
      password: password,
    );
    return login.canBiometricSignIn ? login : null;
  }

  Future<void> saveEmail({
    required String email,
    required String password,
  }) async {
    if (!isSupported) return;
    await _storage.write(key: _providerKey, value: SavedLoginProvider.email.name);
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<void> saveGoogle({required String email}) async {
    if (!isSupported) return;
    await _storage.write(
      key: _providerKey,
      value: SavedLoginProvider.google.name,
    );
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.delete(key: _passwordKey);
  }

  Future<void> clear() async {
    if (!isSupported) return;
    await Future.wait<void>([
      _storage.delete(key: _providerKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _passwordKey),
    ]);
  }
}
