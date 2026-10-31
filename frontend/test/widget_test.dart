import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/app/app.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeFirebaseAuthService implements FirebaseAuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut([WidgetRef? ref]) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(FakeFirebaseAuthService()),
        ],
        child: const ReceiptoApp(),
      ),
    );

    // Verify that our app is displayed
    expect(find.byType(ReceiptoApp), findsOneWidget);
  });
}
