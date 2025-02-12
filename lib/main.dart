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

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Show lightweight splash screen first
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

  /// 🔹 **Deferred Initialization of Firebase & OneSignal**
  Future<void> _initializeApp() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await _initOneSignal();
    _setupFirebaseMessaging();
    await _loadUser();

    // 🔹 Update UI after async tasks complete
    setState(() => _isInitialized = true);
  }

  /// 🔹 **Fetch the logged-in user from Firebase**
  Future<void> _loadUser() async {
    final auth = FirebaseAuth.instance;
    final User? firebaseUser = auth.currentUser;

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

  /// 🔹 **Initialize OneSignal in Background**
  Future<void> _initOneSignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize("fd8faa8e-c8a0-4c91-8c93-62665f576d75");
      await OneSignal.Notifications.requestPermission(true);
      OneSignal.Notifications.addClickListener((event) async {
        final dataOnesignal = event.notification.additionalData;
        if (dataOnesignal != null && dataOnesignal['chatID'] != null) {
          final chatID = dataOnesignal["chatID"];
          // GET ALL DATA FOR CHAT AND NAVIGATE TO CHAT SCREEN
          print("GOT CLICKED ON PUSH NOTIFICATIONS");
          final chatData = await FirebaseFirestore.instance
              .collection("private_chats")
              .doc(chatID)
              .get();
          final data = chatData.data() as Map<String, dynamic>;

          (data["participants"] as List<dynamic>)
              .firstWhere((id) => id != FirebaseAuth.instance.currentUser?.uid);

          final User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChatMembersScreen(
                  user: currentUser,
                ),
              ),
            );
          } else {
            debugPrint("❌ No user is currently logged in");
          }
        }
      });
    } catch (e) {
      debugPrint("❌ OneSignal Init Error: $e");
    }
  }

  /// 🔹 **Setup Firebase Messaging**
  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 New message: ${message.notification?.title}");
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📨 User tapped notification: ${message.data}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
            create: (_) =>
                // ignore: dead_code
                false ? MockAuthRepository() : FirebaseAuthRepository()),
        Provider<DatabaseRepository>(create: (_) => DatabaseRepository()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: _isInitialized
            ? (_loggedInUser != null ? const HomeScreen() : const StartScreen())
            : const SplashScreen(), // 🔹 Show splash while loading
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
        child: CircularProgressIndicator(), // 🔹 Lightweight loading UI
      ),
    );
  }
}
