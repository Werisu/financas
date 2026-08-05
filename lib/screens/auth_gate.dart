import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/biometric_lock_screen.dart';
import 'package:financas/screens/home_shell.dart';
import 'package:financas/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erro de autenticação: $error'),
          ),
        ),
      ),
      data: (user) {
        if (user == null) return const LoginScreen();

        final session = ref.watch(sessionReadyProvider);
        return session.when(
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sincronizando seus dados...'),
                ],
              ),
            ),
          ),
          error: (error, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Falha ao sincronizar: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(sessionReadyProvider),
                      child: const Text('Tentar novamente'),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(authServiceProvider).signOut(),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (_) => const AppLockGate(child: HomeShell()),
        );
      },
    );
  }
}
