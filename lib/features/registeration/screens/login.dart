import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoppy_club/features/profiles/screens/edit_profile_screen.dart';
import 'package:hoppy_club/features/registeration/repository/user.dart';
import 'package:hoppy_club/features/registeration/repository/user_service.dart';
import 'package:hoppy_club/features/registeration/widgets/signup_button.dart';
import 'package:hoppy_club/features/registeration/widgets/signup_login.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userService = UserService();

  String? successMessage;
  String? errorMessage;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  // Load saved credentials if "Remember Me" is checked
  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;

    if (savedRememberMe) {
      setState(() {
        userService.emailController.text = savedEmail;
        userService.passwordController.text = savedPassword;
        rememberMe = savedRememberMe;
      });
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setBool('rememberMe', true);
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.setBool('rememberMe', false);
  }

  void handleLogin(BuildContext context) async {
    setState(() {
      errorMessage = null;
      successMessage = null;
      isLoading = true;
    });

    try {
      // Attempt to sign in using Firebase Authentication
      final response = await userService.login();

      if (response.success) {
        if (rememberMe) {
          await saveCredentials(
            userService.emailController.text,
            userService.passwordController.text,
          );
        } else {
          await clearSavedCredentials();
        }

        setState(() => successMessage =
            "Welcome ${response.user!.isAdmin ? "Admin" : "User"}");

        await Future.delayed(const Duration(seconds: 1));

        navigateToUserScreen(response.user!);
      } else {
        setState(() => errorMessage = response.errorMessage);
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: ${e.toString()}";
      });
    }

    setState(() => isLoading = false);
  }

  void navigateToUserScreen(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Image.asset('assets/icons/Group 3052.png',
                  width: 100, height: 100),
              const SizedBox(height: 20),
              const Text(
                'Hi, Welcome Back! 👋',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 20),

              // Email Input
              TextField(
                controller: userService.emailController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: 'example@gmail.com',
                  hintStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 10),

              // Password Input
              TextField(
                controller: userService.passwordController,
                obscureText: !isPasswordVisible,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black),
                  hintText: 'Enter Your Password',
                  hintStyle: const TextStyle(color: Colors.black54),
                  suffixIcon: IconButton(
                    icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 10),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

              // Remember Me Checkbox
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  const Text(
                    'Remember Me',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Login Button
              ElevatedButton(
                onPressed: () => handleLogin(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.purple,
                ),
                child: const Text('Log In'),
              ),

              const SizedBox(height: 20),

              if (successMessage != null)
                Text(successMessage!,
                    style: const TextStyle(color: Colors.green)),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              if (isLoading) const CircularProgressIndicator(),

              const SizedBox(height: 40),

              // Social Login Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.black, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Text("Or With", style: TextStyle(color: Colors.black)),
                  ),
                  Expanded(child: Divider(color: Colors.black, thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Social Media Buttons Placeholder
              IconScroller(),

              const SizedBox(height: 30),

              // Sign Up Option
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: Colors.black)),
                  SignupButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
