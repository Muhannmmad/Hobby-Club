import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoppy_club/features/registeration/widgets/signup_button.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });
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

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': true, // ✅ Mark user as online
          'lastSeen': FieldValue.serverTimestamp(), // ✅ Update last seen
        });

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

  /// Updates online status when app state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      if (state == AppLifecycleState.resumed) {
        updateOnlineStatus(userId, true); // User is back online
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached) {
        updateOnlineStatus(userId, false); // User is offline
      }
    }
  }

  /// Updates Firestore online status
  void updateOnlineStatus(String userId, bool isOnline) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((e) => print("Error updating online status: $e"));
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
              Image.asset(
                'assets/icons/Group 3052.png',
                width: isTablet ? 150 : 100,
                height: isTablet ? 150 : 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Hi, Welcome Back! 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: emailController,
                label: 'Email',
                hint: 'example@gmail.com',
                isPassword: false,
              ),
              const SizedBox(height: 10),
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
              ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 18 : 15,
                    horizontal: isTablet ? 100 : 80,
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Log In',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              if (successMessage != null)
                Text(successMessage!,
                    style: const TextStyle(color: Colors.green)),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 40),
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
