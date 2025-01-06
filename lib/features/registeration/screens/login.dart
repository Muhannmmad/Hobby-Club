import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoppy_club/features/registeration/widgets/signup_button.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool rememberMe = false;

  String? successMessage;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';
    final savedPassword = prefs.getString('password') ?? '';
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;

    if (savedRememberMe) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
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

  Future<void> handleLogin() async {
    setState(() {
      errorMessage = null;
      successMessage = null;
      isLoading = true;
    });

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = "Email and Password cannot be empty";
        isLoading = false;
      });
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        if (rememberMe) {
          await saveCredentials(emailController.text, passwordController.text);
        } else {
          await clearSavedCredentials();
        }

        setState(() => successMessage = "Welcome back!");

        await Future.delayed(const Duration(seconds: 1));

        navigateToNextScreen(user);
      }
    } catch (e) {
      setState(() {
        errorMessage = "Invalid email or password. Please try again.";
      });
    }

    setState(() => isLoading = false);
  }

  void navigateToNextScreen(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 30.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),

              // App Logo
              Image.asset(
                'assets/icons/Group 3052.png',
                width: isTablet ? 150 : 100,
                height: isTablet ? 150 : 100,
              ),
              const SizedBox(height: 20),

              const Text(
                'Hi, Welcome Back! 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Email Input
              buildTextField(
                controller: emailController,
                label: 'Email',
                hint: 'example@gmail.com',
                isPassword: false,
              ),
              const SizedBox(height: 10),

              // Password Input
              buildTextField(
                controller: passwordController,
                label: 'Password',
                hint: 'Enter Your Password',
                isPassword: true,
                toggleVisibility: () {
                  setState(() => isPasswordVisible = !isPasswordVisible);
                },
                isPasswordVisible: isPasswordVisible,
              ),
              const SizedBox(height: 10),

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
                  ),
                  const Text('Remember Me'),
                ],
              ),

              const SizedBox(height: 10),

              // Login Button
              ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 18 : 15,
                    horizontal: isTablet ? 100 : 80,
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Log In'),
              ),

              const SizedBox(height: 20),

              // Messages
              if (successMessage != null)
                Text(successMessage!,
                    style: const TextStyle(color: Colors.green)),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 40),

              // Sign Up Option
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  SignupButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
