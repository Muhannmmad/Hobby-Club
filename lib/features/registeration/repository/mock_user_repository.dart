import 'dart:async';
import 'server_user_response.dart';
import 'user.dart';
import 'user_repository.dart';
import 'mock_user_database.dart';

class MockUserRepository implements UserRepository {
  @override
  Future<ServerUserResponse> loginAndGetUser(
      String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.endsWith("@test.de")) {
      if (password == "123") {
        final user = email.startsWith("test") ? normalUser : adminUser;
        return ServerUserResponse(success: true, user: user);
      } else {
        return ServerUserResponse(
            success: false, errorMessage: "Password is invalid");
      }
    } else {
      return ServerUserResponse(success: false, errorMessage: "User not found");
    }
  }

  @override
  Future<ServerUserResponse> registerUser(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.isNotEmpty) {
      final user = User(email: email, password: password);
      return ServerUserResponse(success: true, user: user);
    } else {
      return ServerUserResponse(
          success: false, errorMessage: "Invalid email or password");
    }
  }
}
