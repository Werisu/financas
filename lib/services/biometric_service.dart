import 'package:financas/data/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  static const _enabledKey = 'biometric_enabled';

  final LocalAuthentication _auth;
  bool _busy = false;

  bool get isBusy => _busy;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isEnabled =>
      AppDatabase.meta.get(_enabledKey, defaultValue: false) as bool;

  Future<void> setEnabled(bool value) async {
    await AppDatabase.meta.put(_enabledKey, value);
  }

  Future<bool> canUseBiometrics() async {
    if (!isSupportedPlatform) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Desbloqueie o Finanças',
  }) async {
    if (!isSupportedPlatform || _busy) return false;
    _busy = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }
}
