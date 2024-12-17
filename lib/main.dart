import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/start/screens/start_screen.dart';
import 'package:hoppy_club/firebase_options.dart';
import 'package:hoppy_club/features/registeration/repository/auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/mock_auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/firebase_auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const bool useMockAuth = false;
  final AuthRepository authRepository =
      useMockAuth ? MockAuthRepository() : FirebaseAuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}
