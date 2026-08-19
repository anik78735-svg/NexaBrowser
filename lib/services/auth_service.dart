import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Result of a sign-in attempt. [user] is non-null only on success;
/// otherwise [errorMessage] explains what went wrong so the UI can show
/// something more useful than a generic "cancelled or failed" snackbar.
class SignInResult {
  final User? user;
  final String? errorMessage;
  const SignInResult({this.user, this.errorMessage});
}

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

  /// Attempts Google sign-in. On failure, [SignInResult.errorMessage] carries
  /// a human-readable reason instead of silently swallowing the exception —
  /// the previous version returned null for every failure (including real
  /// config errors), which is why sign-in looked like it was permanently
  /// "cancelled or failed" with no way to tell why.
  static Future<SignInResult> signInWithGoogle() async {
    try {
      await _ensureInitialized();
    } catch (e) {
      debugPrint('AuthService: GoogleSignIn.initialize() failed: $e');
      return const SignInResult(
        errorMessage:
            "Google Sign-In isn't configured correctly for this app build "
            "(check the web client ID / google-services.json).",
      );
    }

    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication auth = account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return SignInResult(user: userCredential.user);
    } on GoogleSignInException catch (e) {
      debugPrint('AuthService: GoogleSignInException ${e.code}: ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User closed the account picker — not an error worth surfacing.
        return const SignInResult();
      }
      return SignInResult(
        errorMessage: "Google Sign-In failed (${e.code.name}). "
            "This is usually a mismatched SHA-1 fingerprint or package name "
            "in the Firebase console, not something the app itself can fix.",
      );
    } on PlatformException catch (e) {
      // code 10 = DEVELOPER_ERROR: almost always a SHA-1 certificate
      // fingerprint (debug vs release keystore) that isn't registered
      // for this app in the Firebase / Google Cloud console, or an
      // applicationId that doesn't match google-services.json.
      debugPrint('AuthService: PlatformException ${e.code}: ${e.message}');
      final hint = e.code == '10' || e.code == 'sign_in_failed'
          ? " (code ${e.code}: likely a SHA-1 fingerprint not registered "
              "for this build's keystore in the Firebase console)"
          : " (code ${e.code})";
      return SignInResult(errorMessage: "Google Sign-In failed$hint.");
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException ${e.code}: ${e.message}');
      return SignInResult(
        errorMessage: e.message ?? "Firebase sign-in failed (${e.code}).",
      );
    } catch (e) {
      debugPrint('AuthService: sign-in failed: $e');
      return SignInResult(errorMessage: "Sign-in failed: $e");
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}