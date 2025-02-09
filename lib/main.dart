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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const bool useMockAuth = false;
  final AuthRepository authRepository =
      // ignore: dead_code
      useMockAuth ? MockAuthRepository() : FirebaseAuthRepository();

  final DatabaseRepository databaseRepository = DatabaseRepository();

  // Determine the initial screen based on authentication state
  UserModel? loggedInUser = await getLoggedInUser();

  runApp(MultiProvider(
    providers: [
      Provider<AuthRepository>(create: (_) => authRepository),
      Provider<DatabaseRepository>(create: (_) => databaseRepository),
      ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(user: loggedInUser)),
    ],
    child: MyApp(
        startScreen:
            loggedInUser != null ? const HomeScreen() : const StartScreen()),
  ));
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
    debugPrint("Error fetching user data: $e");
  }

  return null;
}

/// App's root widget that decides the initial screen
class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: startScreen,
    );
  }
}

void setupFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    ("New message: ${message.notification?.title}");
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    ("User tapped notification: ${message.data}");
  });
}

void requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    ('User granted permission');
  } else {
    ('User denied permission');
  }
}

/// UserProvider to manage logged-in user data
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
