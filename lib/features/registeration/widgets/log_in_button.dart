import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/screens/login.dart';

class LogInButton extends StatelessWidget {
  const LogInButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      child: const SizedBox(
        child: Text(
          'Log in',
          style: TextStyle(
            color: Color.fromARGB(255, 43, 0, 73),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
