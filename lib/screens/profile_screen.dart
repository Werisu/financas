import 'dart:typed_data';

import 'package:financas/providers/biometric_providers.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/services/profile_service.dart';
import 'package:financas/theme/app_theme.dart';
import 'package:financas/utils/profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _uploadingPhoto = false;
  bool _initialized = false;
  String? _photoBase64;
  String? _photoUrl;
  Uint8List? _localPreview;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile() {
    if (_initialized) return;
    final profile = ref.read(userProfileProvider).asData?.value;
    final user = ref.read(authServiceProvider).currentUser;
    _nameController.text =
        profile?.displayName ?? user?.displayName ?? '';
    _photoBase64 = profile?.photoBase64;
    _photoUrl = profile?.photoUrl ?? user?.photoURL;
    _initialized = true;
  }

  Future<void> _pickAndSavePhoto() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() {
      _error = null;
      _uploadingPhoto = true;
    });

    try {
      final photo = await ref
          .read(profileServiceProvider)
          .pickCompressedProfileImage();
      if (photo == null) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      await ref.read(repositoryProvider).updateProfile(
            photoBase64: photo.base64,
          );

      setState(() {
        _localPreview = photo.bytes;
        _photoBase64 = photo.base64;
        _photoUrl = null;
      });
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada.')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final ok = await ref.read(biometricEnabledProvider.notifier).enable();
      if (!mounted) return;
      if (ok) {
        ref.read(appLockedProvider.notifier).unlock();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Desbloqueio por digital ativado.'),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ativar a biometria.'),
          ),
        );
      }
    } else {
      await ref.read(biometricEnabledProvider.notifier).disable();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Desbloqueio por digital desativado.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      await ref.read(authServiceProvider).updateDisplayName(name);
      await ref.read(repositoryProvider).updateProfile(displayName: name);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil salvo.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      final auth = ref.read(authServiceProvider);
      setState(() => _error = auth.mapError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider);
    _hydrateFromProfile();

    final user = ref.watch(authStateProvider).asData?.value;
    final scheme = Theme.of(context).colorScheme;
    final image = profileImageProvider(
      photoBase64: _photoBase64,
      photoUrl: _photoUrl,
      localBytes: _localPreview,
    );
    final initials = _initials(
      _nameController.text.isNotEmpty
          ? _nameController.text
          : (user?.email ?? '?'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        backgroundImage: image,
                        child: image == null
                            ? Text(
                                initials,
                                style: GoogleFonts.fraunces(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploadingPhoto ? null : _pickAndSavePhoto,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Toque na câmera para escolher uma foto',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.ink.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
                    hintText: 'Como você quer aparecer no app',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Informe um nome com pelo menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: user?.email ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                  ),
                ),
                const SizedBox(height: 24),
                _BiometricToggle(onChanged: _toggleBiometric),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _loading ? null : _saveProfile,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Salvar perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _BiometricToggle extends ConsumerWidget {
  const _BiometricToggle({required this.onChanged});

  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(biometricAvailableProvider);
    final enabled = ref.watch(biometricEnabledProvider);
    final scheme = Theme.of(context).colorScheme;

    return available.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (canUse) {
        if (!canUse) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: AppTheme.ink.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Biometria indisponível neste dispositivo',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: SwitchListTile(
            value: enabled,
            onChanged: (value) => onChanged(value),
            secondary: Icon(Icons.fingerprint, color: scheme.primary),
            title: Text(
              'Desbloquear com digital',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Peça a digital ou o PIN do celular ao abrir o app',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        );
      },
    );
  }
}
