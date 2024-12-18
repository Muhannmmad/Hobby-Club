import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Mock sign-in successful for email: $email');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(seconds: 1));
    print('Mock sign-out successful');
  }
}
