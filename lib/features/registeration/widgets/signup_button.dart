import 'package:flutter/material.dart';
import 'package:hoppy_club/features/registeration/screens/signup.dart';

class SignupButton extends StatelessWidget {
  const SignupButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SignUpScreen(),
          ),
        );
      },
      child: const SizedBox(
        child: Text(
          'Sign Up',
          style: TextStyle(
            color: Color.fromARGB(255, 43, 0, 73),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
