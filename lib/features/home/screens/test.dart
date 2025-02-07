import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message Received: ${message.notification?.title}");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _token = "Fetching...";

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions (needed for iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Notifications permission granted");
    } else {
      print("Notifications permission denied");
    }

    // Get FCM token
    String? token = await messaging.getToken();
    setState(() {
      _token = token ?? "Failed to get token";
    });
    print("FCM Token: $_token");

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message Received: ${message.notification?.title}");
      _showMessageDialog(message);
    });

    // Handle notification taps (app in background or terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.notification?.title}");
    });
  }

  void _showMessageDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? "No Title"),
        content: Text(message.notification?.body ?? "No Body"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("FCM Test")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("FCM Token:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_token),
              const SizedBox(height: 20),
              const Text("Send a notification from Firebase Console to test."),
            ],
          ),
        ),
      ),
    );
  }
}
