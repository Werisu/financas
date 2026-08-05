import 'package:financas/providers/biometric_providers.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/services/saved_login_service.dart';
import 'package:financas/theme/app_theme.dart';
import 'package:financas/utils/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;
  bool _saveLogin = false;
  bool _useOtherAccount = false;
  bool _biometricAttempted = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _maybeAutoBiometric(SavedLogin? saved, bool canUseBiometric) {
    if (_biometricAttempted ||
        _loading ||
        _registerMode ||
        _useOtherAccount ||
        !canUseBiometric ||
        saved == null) {
      return;
    }
    _biometricAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _submitBiometric(saved);
    });
  }

  Future<void> _persistLoginIfNeeded({
    required SavedLoginProvider provider,
    required String email,
    String? password,
  }) async {
    if (!_saveLogin) return;
    final auth = ref.read(authServiceProvider);
    await auth.saveLoginAfterSignIn(
      provider: provider,
      email: email,
      password: password,
    );
    await ref.read(biometricEnabledProvider.notifier).enable(requirePrompt: false);
    ref.invalidate(savedLoginProvider);
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    final email = _email.text.trim();
    final password = _password.text;
    try {
      if (_registerMode) {
        await auth.registerWithEmail(email: email, password: password);
      } else {
        await auth.signInWithEmail(email: email, password: password);
      }
      await _persistLoginIfNeeded(
        provider: SavedLoginProvider.email,
        email: email,
        password: password,
      );
    } catch (e) {
      setState(() => _error = auth.mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      final cred = await auth.signInWithGoogle();
      final email = cred.user?.email;
      if (email != null) {
        await _persistLoginIfNeeded(
          provider: SavedLoginProvider.google,
          email: email,
        );
      }
    } catch (e) {
      setState(() => _error = auth.mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitBiometric(SavedLogin saved) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    final biometric = ref.read(biometricServiceProvider);
    try {
      final ok = await biometric.authenticate(
        reason: 'Entre no Finanças com a digital',
      );
      if (!ok) {
        setState(() => _error = 'Biometria cancelada ou falhou.');
        return;
      }
      await auth.signInWithSavedLogin(saved);
      ref.read(appLockedProvider.notifier).unlock();
    } catch (e) {
      setState(() => _error = auth.mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final savedLogin = ref.watch(savedLoginProvider);
    final canUseBiometric = biometricAvailable.asData?.value ?? false;
    final saved = savedLogin.asData?.value;
    final showBiometricEntry =
        !_registerMode && !_useOtherAccount && canUseBiometric && saved != null;

    _maybeAutoBiometric(saved, canUseBiometric);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              AppTheme.background,
              scheme.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppInfo.appName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      showBiometricEntry
                          ? 'Toque na digital para entrar de novo'
                          : 'Entre para sincronizar seus gastos entre celular e web.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppTheme.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (showBiometricEntry) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.fingerprint,
                                size: 64,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                saved.email,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: scheme.error),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed:
                                    _loading ? null : () => _submitBiometric(saved),
                                icon: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.fingerprint),
                                label: Text(
                                  _loading ? 'Entrando...' : 'Entrar com digital',
                                ),
                              ),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(() {
                                          _useOtherAccount = true;
                                          _email.text = saved.email;
                                          _error = null;
                                        }),
                                child: const Text('Usar outra conta'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _registerMode ? 'Criar conta' : 'Entrar',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                  ),
                                  validator: (value) {
                                    if (value == null || !value.contains('@')) {
                                      return 'Informe um e-mail válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: [
                                    _registerMode
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Mínimo de 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                if (!_registerMode && canUseBiometric) ...[
                                  const SizedBox(height: 8),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _saveLogin,
                                    onChanged: _loading
                                        ? null
                                        : (value) => setState(
                                              () => _saveLogin = value ?? false,
                                            ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      'Salvar login para entrar com a digital',
                                      style: GoogleFonts.dmSans(fontSize: 14),
                                    ),
                                  ),
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _loading ? null : _submitEmail,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _registerMode
                                              ? 'Criar conta'
                                              : 'Entrar',
                                        ),
                                ),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() {
                                            _registerMode = !_registerMode;
                                            _error = null;
                                          }),
                                  child: Text(
                                    _registerMode
                                        ? 'Já tenho conta'
                                        : 'Criar nova conta',
                                  ),
                                ),
                                if (saved != null && _useOtherAccount)
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => setState(() {
                                              _useOtherAccount = false;
                                              _error = null;
                                            }),
                                    child: const Text('Voltar ao login com digital'),
                                  ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('ou'),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loading ? null : _submitGoogle,
                                  icon: const Icon(Icons.g_mobiledata, size: 28),
                                  label: const Text('Continuar com Google'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      AppInfo.creditLine,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.ink.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
