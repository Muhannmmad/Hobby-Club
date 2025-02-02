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
    WidgetsBinding.instance.addObserver(this);
    loadSavedCredentials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Detects app lifecycle changes and updates online status
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

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });
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
        updateOnlineStatus(user.uid, true); // Set user as online

        setState(() => successMessage = "Welcome back!");

        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', emailController.text.trim());
          await prefs.setString('password', passwordController.text.trim());
          await prefs.setBool('rememberMe', true);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('email');
          await prefs.remove('password');
          await prefs.setBool('rememberMe', false);
        }

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(
          () => errorMessage = "Invalid email or password. Please try again.");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double baseWidth = 375;
    final double scaleFactor = screenSize.width / baseWidth;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20 * scaleFactor),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100 * scaleFactor),
              Image.asset(
                'assets/icons/Group 3052.png',
                width: 100 * scaleFactor,
                height: 100 * scaleFactor,
              ),
              SizedBox(height: 20 * scaleFactor),
              Text(
                'Hi, Welcome Back! 👋',
                style: TextStyle(
                  fontSize: (12 * scaleFactor).clamp(18, 28),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20 * scaleFactor),
              buildTextField(
                controller: emailController,
                label: 'Email',
                hint: 'example@gmail.com',
                isPassword: false,
                scaleFactor: scaleFactor,
              ),
              SizedBox(height: 10 * scaleFactor),
              buildTextField(
                controller: passwordController,
                label: 'Password',
                hint: 'Enter Your Password',
                isPassword: true,
                toggleVisibility: () {
                  setState(() => isPasswordVisible = !isPasswordVisible);
                },
                isPasswordVisible: isPasswordVisible,
                scaleFactor: scaleFactor,
              ),
              SizedBox(height: 10 * scaleFactor),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (bool? value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text("Remember Me"),
                ],
              ),
              SizedBox(height: 20 * scaleFactor),
              ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(
                    vertical: 8 * scaleFactor,
                    horizontal: 20 * scaleFactor,
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (16 * scaleFactor).clamp(12, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(height: 40 * scaleFactor),
              _buildLoginRow(scaleFactor),
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
    required double scaleFactor,
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
                icon: Icon(isPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: toggleVisibility,
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLoginRow(double scaleFactor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("No account? "),
        Transform.scale(
            scale: scaleFactor.clamp(0.8, 1.2), child: const SignupButton()),
      ],
    );
  }
}
