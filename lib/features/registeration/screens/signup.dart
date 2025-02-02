import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/screens/edit_profile_screen.dart';
import 'package:hoppy_club/features/registeration/widgets/log_in_button.dart';
import 'package:hoppy_club/features/registeration/widgets/signup_login.dart';
import 'package:hoppy_club/features/registeration/repository/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final userService = UserService();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final response = await userService.registerUser(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
        username: _usernameController.text,
      );

      if (response.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              userId:
                  _auth.currentUser!.uid, // Pass the current user ID correctly
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.errorMessage ?? "Sign up failed")),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double baseWidth = 375;
    final double scaleFactor = screenSize.width / baseWidth;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 20 * scaleFactor, vertical: 50 * scaleFactor),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/Group 3052.png',
                  width: 100 * scaleFactor,
                  height: 100 * scaleFactor,
                ),
                SizedBox(height: 20 * scaleFactor),
                Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: (20 * scaleFactor).clamp(20, 32),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10 * scaleFactor),
                Text(
                  'Connect with your friends today!',
                  style: TextStyle(
                    fontSize: (16 * scaleFactor).clamp(12, 18),
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20 * scaleFactor),
                _buildTextField(_usernameController, 'Username', scaleFactor),
                SizedBox(height: 10 * scaleFactor),
                _buildTextField(_emailController, 'Email', scaleFactor),
                SizedBox(height: 10 * scaleFactor),
                _buildPasswordField(_passwordController, 'Enter Your Password',
                    _isPasswordVisible, () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                }, scaleFactor),
                SizedBox(height: 10 * scaleFactor),
                _buildPasswordField(_confirmPasswordController,
                    'Confirm Your Password', _isConfirmPasswordVisible, () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                }, scaleFactor),
                SizedBox(height: 20 * scaleFactor),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 8 * scaleFactor,
                        horizontal: 20 * scaleFactor),
                    textStyle: TextStyle(
                        fontSize: (16 * scaleFactor).clamp(12, 18),
                        fontWeight: FontWeight.bold),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('Sign Up'),
                ),
                SizedBox(height: 20 * scaleFactor),
                _buildDivider(scaleFactor),
                SizedBox(height: 10 * scaleFactor),
                IconScroller(),
                SizedBox(height: 15 * scaleFactor),
                _buildLoginRow(scaleFactor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, double scaleFactor) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: (14 * scaleFactor).clamp(12, 18)),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${label.toLowerCase()}';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      bool isVisible, VoidCallback onTap, double scaleFactor) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: (14 * scaleFactor).clamp(12, 18)),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: (20 * scaleFactor).clamp(16, 24),
          ),
          onPressed: onTap,
        ),
      ),
      validator: (value) {
        if (label == 'Confirm Your Password' &&
            value != _passwordController.text) {
          return 'Passwords do not match';
        }
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildDivider(double scaleFactor) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: (1 * scaleFactor).clamp(0.5, 2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor),
          child: Text(
            "Or With",
            style: TextStyle(
              color: Colors.black,
              fontSize: (14 * scaleFactor).clamp(12, 18),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: (1 * scaleFactor).clamp(0.5, 2),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginRow(double scaleFactor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already a member? ",
          style: TextStyle(
            color: Colors.black,
            fontSize: (14 * scaleFactor).clamp(10, 18),
          ),
        ),
        Transform.scale(
          scale: scaleFactor.clamp(0.8, 1.2),
          child: const LogInButton(),
        ),
      ],
    );
  }
}
