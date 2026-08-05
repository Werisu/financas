import 'package:financas/services/biometric_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(biometricServiceProvider).canUseBiometrics();
});

/// Preferência salva localmente (Hive).
final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  return BiometricEnabledNotifier(ref.watch(biometricServiceProvider));
});

class BiometricEnabledNotifier extends StateNotifier<bool> {
  BiometricEnabledNotifier(this._service) : super(_service.isEnabled);

  final BiometricService _service;

  Future<bool> enable() async {
    final ok = await _service.authenticate(
      reason: 'Confirme para ativar o desbloqueio por digital',
    );
    if (!ok) return false;
    await _service.setEnabled(true);
    state = true;
    return true;
  }

  Future<void> disable() async {
    await _service.setEnabled(false);
    state = false;
  }
}

/// `true` = app bloqueado e precisa de biometria.
final appLockedProvider =
    StateNotifierProvider<AppLockedNotifier, bool>((ref) {
  final enabled = ref.read(biometricServiceProvider).isEnabled;
  return AppLockedNotifier(initiallyLocked: enabled);
});

class AppLockedNotifier extends StateNotifier<bool> {
  AppLockedNotifier({required bool initiallyLocked}) : super(initiallyLocked);

  void lock() => state = true;

  void unlock() => state = false;
}
