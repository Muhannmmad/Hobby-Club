import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase sign-in successful');
    } catch (e) {
      print('Firebase sign-in error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('Firebase sign-out successful');
    } catch (e) {
      print('Firebase sign-out error: $e');
      rethrow;
    }
  }
}
