import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/repository/database_repository.dart';
import 'package:hoppy_club/features/start/screens/start_screen.dart';
import 'package:hoppy_club/firebase_options.dart';
import 'package:hoppy_club/features/registeration/repository/auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/mock_auth_repository.dart';
import 'package:hoppy_club/features/registeration/repository/firebase_auth_repository.dart';
import 'package:provider/provider.dart';

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

  runApp(MultiProvider(
    providers: [
      Provider<AuthRepository>(create: (_) => authRepository),
      Provider<DatabaseRepository>(create: (_) => databaseRepository),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}
