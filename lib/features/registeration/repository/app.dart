import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/screens/login.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: "login",
      onGenerateRoute: (RouteSettings route) {
        switch (route.name) {
          case "login":
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}
