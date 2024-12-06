import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_user_repository.dart';
import 'server_user_response.dart';
import 'user.dart';

class UserService {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mockUserRepository = MockUserRepository();

  // Save user data to SharedPreferences
  Future<void> saveUserToPreferences(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  // Register user and save to SharedPreferences
  Future<ServerUserResponse> registerUser(
      String email, String password, String text,
      {required String username}) async {
    final response = await mockUserRepository.registerUser(email, password);

    if (response.success) {
      await saveUserToPreferences(email, password);
    }

    return response;
  }

  // Login user and check against saved credentials
  Future<ServerUserResponse> login() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    final email = emailController.text;
    final password = passwordController.text;

    if (savedEmail == email && savedPassword == password) {
      return ServerUserResponse(
        success: true,
        user: User(email: savedEmail!, password: savedPassword!),
      );
    } else {
      return ServerUserResponse(
          success: false, errorMessage: "Invalid credentials");
    }
  }

  // Clear saved user data
  Future<void> clearUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }

  clearSavedCredentials() {}
}

void clearSavedCredentials() {
  var emailController;
  emailController.clear();
  var passwordController;
  passwordController.clear();
}
