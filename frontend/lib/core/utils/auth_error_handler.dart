import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  AuthErrorHandler._();

  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered to another account.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
          return 'Invalid email or password. Please verify your credentials.';
        case 'network-request-failed':
          return 'Network connection failed. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many login attempts. Access has been temporarily disabled.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'operation-not-allowed':
          return 'This sign-in method is currently disabled.';
        default:
          return error.message ?? 'An authentication error occurred. Please try again.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
