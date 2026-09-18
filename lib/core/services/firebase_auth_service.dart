import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';
import 'package:receipto/features/notifications/data/services/notification_scheduler.dart';
import 'package:receipto/features/scan/presentation/providers/scan_provider.dart';
import 'package:receipto/features/ai_assistant/data/services/ai_assistant_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  // Getter for the current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes (useful for reactive status changes)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up/Register with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google authentication (google_sign_in v7.x compatible)
  Future<UserCredential?> signInWithGoogle() async {
    // Ensure Google Sign-In is initialized (v7.x requirement)
    await _googleSignIn.initialize();

    // Authenticate (Identity check)
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      return null;
    }

    // Authorize required scopes to obtain the Access Token
    final List<String> scopes = ['email', 'profile'];
    final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

    // Create Firebase Auth Credential using both tokens
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: clientAuth.accessToken,
      idToken: googleUser.authentication.idToken,
    );

    // Sign in to Firebase with the credential
    return await _auth.signInWithCredential(credential);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out from both Firebase and Google accounts and invalidate user caches
  Future<void> signOut([WidgetRef? ref]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_logged_in_email');
      await prefs.remove('last_logged_in_uid');
    } catch (_) {}
    if (ref != null) {
      try {
        await ref.read(notificationSchedulerProvider).cancelAll();
      } catch (_) {}
      try {
        ref.read(scanProvider.notifier).clearState();
      } catch (_) {}
      try {
        ref.read(aiAssistantServiceProvider).clearCache();
      } catch (_) {}
      ref.invalidate(dbReceiptsListProvider);
      ref.invalidate(recycleBinProvider);
      ref.invalidate(dbWarrantiesProvider);
      ref.invalidate(notificationNotifierProvider);
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
