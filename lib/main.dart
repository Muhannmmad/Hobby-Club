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
import 'package:hoppy_club/user_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Handles background FCM messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const bool useMockAuth = false;
  final AuthRepository authRepository =
      useMockAuth ? MockAuthRepository() : FirebaseAuthRepository();

  final DatabaseRepository databaseRepository = DatabaseRepository();

  // Request notification permissions
  await requestNotificationPermissions(); // ✅ Fixed async handling

  // Fetch logged-in user
  UserModel? loggedInUser = await getLoggedInUser();

  runApp(MyApp(
    startScreen:
        loggedInUser != null ? const HomeScreen() : const StartScreen(),
    authRepository: authRepository,
    databaseRepository: databaseRepository,
    loggedInUser: loggedInUser,
  ));
}

/// Requests notification permissions & retrieves FCM token
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    debugPrint("❌ Notifications Denied");
    return;
  } else {
    debugPrint("✅ Notifications Allowed");
  }

  try {
    // For iOS: Ensure APNs token is available
    if (Platform.isIOS) {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        debugPrint("⚠️ APNS token not available yet.");
      } else {
        debugPrint("✅ APNS Token: $apnsToken");
      }
    }

    // Retrieve FCM token (for both iOS & Android)
    String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      debugPrint("🔑 FCM Token: $fcmToken");
    } else {
      debugPrint("⚠️ FCM Token is null");
    }
  } catch (e) {
    debugPrint("❌ Error retrieving FCM Token: $e");
  }
}

/// Fetches the logged-in user from Firebase Authentication & Firestore
Future<UserModel?> getLoggedInUser() async {
  final auth = FirebaseAuth.instance;
  final User? firebaseUser = auth.currentUser;

  if (firebaseUser == null) return null; // No user is logged in

  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (userDoc.exists) {
      return UserModel.fromFirestore(userDoc);
    }
  } catch (e) {
    debugPrint("❌ Error fetching user data: $e");
  }

  return null;
}

/// App's root widget that decides the initial screen
class MyApp extends StatelessWidget {
  final Widget startScreen;
  final AuthRepository authRepository;
  final DatabaseRepository databaseRepository;
  final UserModel? loggedInUser;

  const MyApp({
    super.key,
    required this.startScreen,
    required this.authRepository,
    required this.databaseRepository,
    this.loggedInUser,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => authRepository),
        Provider<DatabaseRepository>(create: (_) => databaseRepository),
        ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(user: loggedInUser)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: startScreen,
      ),
    );
  }
}

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserProvider({UserModel? user}) {
    _user = user;
  }

  UserModel? get user => _user;

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear saved credentials

    // Reset user data and navigate to StartScreen
    setUser(null);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StartScreen()),
    );
  }
}
