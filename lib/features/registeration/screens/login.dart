import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/screens/edit_profile_screen.dart';
import 'package:hoppy_club/features/registeration/screens/signup_login.dart';
import 'package:hoppy_club/features/registeration/screens/signup.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 120, 30, 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/3dgifmaker98011.gif',
                      width: 150, height: 150),
                  const Text(
                    'Hi, Welcome Back! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Text in black
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'example@gmail.com',
                      hintStyle: TextStyle(color: Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TextField(
                    style: TextStyle(color: Colors.black),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Enter Your Password',
                      hintStyle: TextStyle(color: Colors.black54),
                      suffixIcon: Icon(Icons.visibility,
                          color: Colors.black), // Black icon
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.black), // Black border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: true,
                        onChanged: (value) {},
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                        side: const BorderSide(
                          color: Color.fromARGB(210, 0, 0, 0),
                          width: 2,
                        ),
                      ),
                      const Text(
                        'Remember Me',
                        style: TextStyle(color: Colors.black),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 120),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 76, 255),
                    ),
                    child: const Text('Log In'),
                  ),
                  const SizedBox(height: 60),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: Divider(
                          color: Colors.black,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "Or With",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.black,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  IconScroller(),
                  const SizedBox(height: 30),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?     ",
                        style: TextStyle(color: Colors.black),
                      ),
                      SignupButton()
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
