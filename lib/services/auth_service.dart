import 'package:financas/services/saved_login_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    SavedLoginService? savedLogin,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _savedLogin = savedLogin ?? SavedLoginService();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final SavedLoginService _savedLogin;
  bool _googleInitialized = false;

  SavedLoginService get savedLogin => _savedLogin;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || kIsWeb) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      return _auth.signInWithPopup(provider);
    }

    await _ensureGoogleInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Não foi possível obter o token do Google.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithGoogleLightweight() async {
    if (kIsWeb) return null;
    await _ensureGoogleInitialized();
    final future = _googleSignIn.attemptLightweightAuthentication();
    if (future == null) return null;
    final account = await future;
    if (account == null) return null;
    final idToken = account.authentication.idToken;
    if (idToken == null) return null;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithSavedLogin(SavedLogin login) async {
    switch (login.provider) {
      case SavedLoginProvider.email:
        final password = login.password;
        if (password == null || password.isEmpty) {
          throw StateError('Login salvo incompleto. Entre com e-mail e senha.');
        }
        return signInWithEmail(email: login.email, password: password);
      case SavedLoginProvider.google:
        final light = await _signInWithGoogleLightweight();
        if (light != null) return light;
        return signInWithGoogle();
    }
  }

  Future<void> saveLoginAfterSignIn({
    required SavedLoginProvider provider,
    required String email,
    String? password,
  }) async {
    if (provider == SavedLoginProvider.email) {
      if (password == null || password.isEmpty) {
        throw StateError('Senha necessária para salvar o login.');
      }
      await _savedLogin.saveEmail(email: email, password: password);
    } else {
      await _savedLogin.saveGoogle(email: email);
    }
  }

  Future<void> forgetSavedLogin() => _savedLogin.clear();

  Future<void> signOut({bool forgetSavedLogin = false}) async {
    if (forgetSavedLogin) {
      await _savedLogin.clear();
    }

    final saved = forgetSavedLogin ? null : await _savedLogin.read();
    final keepGoogleSession = saved?.provider == SavedLoginProvider.google;

    if (!kIsWeb && !keepGoogleSession) {
      try {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Nenhum usuário autenticado.');
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Nenhum usuário autenticado.');
    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }

  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  String mapError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Este e-mail já está em uso.';
        case 'weak-password':
          return 'A senha deve ter pelo menos 6 caracteres.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente em breve.';
        case 'popup-closed-by-user':
          return 'Login com Google cancelado.';
        default:
          return error.message ?? 'Falha na autenticação.';
      }
    }
    return error.toString();
  }
}
