import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  //---------------------------------------------------------------------
  // This is the "client_type": 3 (Web client) ID from google-services.json.
  // google_sign_in needs this on Android to get a valid ID token that
  // Firebase can verify â€” without it, sign-in silently cancels/fails
  // even when everything else (SHA-1, package name) is correct.
  //---------------------------------------------------------------------
  static const String _webClientId =
      "572356555340-92na943m0m7np1pudjthhqkbpom29pa9.apps.googleusercontent.com";

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _initialized = true;
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static bool get isSignedIn => currentUser != null;

  /// Returns the signed-in Firebase user, or null if the user cancelled
  /// or sign-in failed.
  static Future<User?> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication auth = account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // User cancelled the picker, or sign-in failed.
      return null;
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}