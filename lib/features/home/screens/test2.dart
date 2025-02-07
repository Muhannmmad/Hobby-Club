import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background & Terminated Message Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
      "🌙 Background Message: ${message.notification?.title} - ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _token = "Fetching token...";

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request Permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Notifications Enabled");
    } else {
      print("🚫 Notifications Denied");
      return;
    }

    // Get FCM Token
    String? token = await messaging.getToken();
    setState(() {
      _token = token ?? "Failed to get token";
    });
    print("🔑 FCM Token: $_token");

    // Listen for Foreground Notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          "📩 Foreground Message: ${message.notification?.title} - ${message.notification?.body}");
      _showNotificationDialog(message);
    });

    // Handle Notification Clicks (Background & Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification Clicked: ${message.notification?.title}");
    });
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? "No Title"),
        content: Text(message.notification?.body ?? "No Body"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("FCM Auto Setup Test")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🔑 FCM Token:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_token),
              SizedBox(height: 20),
              Text("Send a test notification from Firebase Console."),
            ],
          ),
        ),
      ),
    );
  }
}
