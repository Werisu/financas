import 'package:financas/providers/biometric_providers.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Envolve o app autenticado: bloqueia com biometria ao abrir ou voltar.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    final enabled = ref.read(biometricEnabledProvider);
    final busy = ref.read(biometricServiceProvider).isBusy;
    if (enabled && !busy) {
      ref.read(appLockedProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(biometricEnabledProvider, (prev, next) {
      if (!next) {
        ref.read(appLockedProvider.notifier).unlock();
      }
    });

    final enabled = ref.watch(biometricEnabledProvider);
    final locked = ref.watch(appLockedProvider);

    if (enabled && locked) {
      return const BiometricLockScreen();
    }
    return widget.child;
  }
}

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final ok = await ref.read(biometricServiceProvider).authenticate(
          reason: 'Desbloqueie o Finanças',
        );

    if (!mounted) return;

    if (ok) {
      ref.read(appLockedProvider.notifier).unlock();
    } else {
      setState(() {
        _authenticating = false;
        _error = 'Não foi possível desbloquear. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: scheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Finanças',
                  style: GoogleFonts.fraunces(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a digital ou o desbloqueio do celular para entrar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.ink.withValues(alpha: 0.6),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _unlock,
                  icon: _authenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(
                    _authenticating ? 'Aguardando...' : 'Desbloquear',
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      ref.read(authServiceProvider).signOut(),
                  child: const Text('Sair da conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
