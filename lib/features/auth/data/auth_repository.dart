import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_config.dart';

/// Kegagalan login dengan pesan yang siap ditampilkan ke pengguna.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Membungkus Firebase Auth + Google Sign-In (PRD F1).
/// UI tidak boleh memanggil kedua paket itu langsung.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  /// Emit user saat login/logout. Sesi login tersimpan di perangkat,
  /// jadi aplikasi tetap masuk walau dibuka tanpa internet.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // google_sign_in v7 mewajibkan initialize() dipanggil tepat satu kali.
  Future<void> _ensureInitialized() async {
    if (isGoogleClientIdMissing) {
      throw const AuthFailure(
        'Web client ID belum diisi. Buka lib/core/config/google_config.dart.',
      );
    }
    _initialization ??=
        _googleSignIn.initialize(serverClientId: kGoogleServerClientId);
    await _initialization;
  }

  /// true = berhasil masuk, false = dibatalkan / tidak ada akun Google.
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google tidak mengirim token login. Coba lagi.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthFailure('Login Google gagal (${e.code.name}).');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthFailure(
          'Login pertama butuh internet. Cek koneksimu lalu coba lagi.',
        );
      }
      throw AuthFailure('Login ke Firebase gagal (${e.code}).');
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Tetap lanjut keluar dari Firebase walau sisi Google gagal.
    }
    await _auth.signOut();
  }
}
