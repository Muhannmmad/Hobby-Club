import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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

  void saveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.FirebaseAuth.instance.currentUser!.uid)
          .update({
        'fcmToken': token,
      });
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
