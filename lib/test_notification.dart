/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (for when the app is in the background or terminated)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔹 Background Message: ${message.notification?.title}");
}

// Local Notifications setup
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? fcmToken = "Fetching...";

  @override
  void initState() {
    super.initState();
    initNotifications();
  }

  // Initialize Notifications
  Future<void> initNotifications() async {
    // Request Notification Permissions
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Notifications Allowed");
    } else {
      print("❌ Notifications Denied");
      return;
    }

    // Get FCM Token
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔑 FCM Token: $token");
    setState(() {
      fcmToken = token;
    });

    // Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Message: ${message.notification?.title}");
      showLocalNotification(message);
    });

    // When the app is opened by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification Clicked! Opened App.");
    });

    // Local Notification Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show Local Notification when a push notification arrives
  void showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id', // Channel ID
      'Chat Notifications', // Channel Name
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "You have a new message",
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("FCM Notification Test")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("FCM Token:", style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: EdgeInsets.all(10),
                child: SelectableText(fcmToken ?? "Fetching...",
                    textAlign: TextAlign.center),
              ),
              ElevatedButton(
                onPressed: () {
                  print("🔄 Refreshing FCM Token...");
                  initNotifications();
                },
                child: Text("Refresh Token"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
