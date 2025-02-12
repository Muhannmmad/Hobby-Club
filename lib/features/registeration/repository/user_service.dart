import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_user_response.dart';
import 'user.dart' as custom_user;

class UserService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Save user data to SharedPreferences
  Future<void> saveUserToPreferences(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  // Register user with Firebase Authentication and save to Firestore
  Future<ServerUserResponse> registerUser(
      String email, String password, String text,
      {required String username}) async {
    try {
      // Register user with Firebase Authentication
      firebase_auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details (username, email) to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Optionally, save the user credentials to SharedPreferences
      await saveUserToPreferences(email, password);

      return ServerUserResponse(success: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServerUserResponse(success: false, errorMessage: e.message);
    }
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
        user: custom_user.User(email: savedEmail!, password: savedPassword!),
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

  // Clear saved credentials
  void clearSavedCredentials() {
    emailController.clear();
    passwordController.clear();
  }
}
