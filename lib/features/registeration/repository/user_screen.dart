import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/repository/user.dart';

// Der User-Screen der den User erhält und die Daten auf dem
// Screen anzeigt
class UserScreen extends StatelessWidget {
  final User user;
  const UserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user.email),
            const SizedBox(
              height: 10,
            ),
            Text(user.password),
            const SizedBox(
              height: 10,
            ),
            Text(user.name),
            const SizedBox(
              height: 10,
            ),
            Text(user.isAdmin ? "Admin" : "User")
          ],
        ),
      ),
    );
  }
}
