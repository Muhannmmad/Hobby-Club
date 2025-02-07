import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/screens/test2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get FCM Token
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground Notification Received: ${message.notification?.title}");
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Notification Clicked: ${message.notification?.title}");
  });

  runApp(MyApp());
}
