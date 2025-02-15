import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/repository/database_repository.dart';
import 'package:hoppy_club/features/start/screens/start_screen.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';
import 'package:hoppy_club/firebase_options.dart';
import 'package:hoppy_club/features/registeration/repository/auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/mock_auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/firebase_auth_repository.dart';
import 'package:hoppy_club/shared/widgets/chat_members.dart';
import 'package:hoppy_club/user_model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UserModel? _loggedInUser;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 🔹 **Initialize Firebase & OneSignal**
  Future<void> _initializeApp() async {
    await _initOneSignal();
    await _setupFirebaseMessaging();
    await _loadUser();
    setState(() => _isInitialized = true);
  }

  /// 🔹 **Fetch logged-in user from Firebase**
  Future<void> _loadUser() async {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (userDoc.exists) {
          _loggedInUser = UserModel.fromFirestore(userDoc);
        }
      } catch (e) {
        debugPrint("❌ Error fetching user data: $e");
      }
    }
  }

  /// 🔹 **Initialize OneSignal**
  Future<void> _initOneSignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize("fd8faa8e-c8a0-4c91-8c93-62665f576d75");
      await OneSignal.Notifications.requestPermission(true);

      OneSignal.Notifications.addClickListener((event) async {
        final dataOnesignal = event.notification.additionalData;
        if (dataOnesignal != null && dataOnesignal['chatID'] != null) {
          final String chatID = dataOnesignal["chatID"];
          _navigateToChatScreen(chatID);
        }
      });
    } catch (e) {
      debugPrint("❌ OneSignal Init Error: $e");
    }
  }

  /// 🔹 **Setup Firebase Cloud Messaging**
  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 New message received: ${message.notification?.title}");
    });

    // Handle when the app is opened by a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📨 Notification tapped: ${message.data}");
      if (message.data.containsKey("chatID")) {
        _navigateToChatScreen(message.data["chatID"]);
      }
    });

    // Handle notification when app is launched from a terminated state
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey("chatID")) {
      _navigateToChatScreen(initialMessage.data["chatID"]);
    }
  }

  /// 🔹 **Navigate to Chat Screen**
  void _navigateToChatScreen(String chatID) async {
    debugPrint("📬 Navigating to chat screen: $chatID");

    final chatData = await FirebaseFirestore.instance
        .collection("private_chats")
        .doc(chatID)
        .get();

    if (chatData.exists) {
      final data = chatData.data() as Map<String, dynamic>;

      if (FirebaseAuth.instance.currentUser != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatMembersScreen(
              user: FirebaseAuth.instance.currentUser!,
            ),
          ),
        );
      } else {
        debugPrint("❌ No user is logged in.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
            create: (_) =>
                false ? MockAuthRepository() : FirebaseAuthRepository()),
        Provider<DatabaseRepository>(create: (_) => DatabaseRepository()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: _isInitialized
            ? (_loggedInUser != null ? const HomeScreen() : const StartScreen())
            : const SplashScreen(),
      ),
    );
  }
}

/// 🔹 **Simple Splash Screen**
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
