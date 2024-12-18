import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class IconScroller extends StatelessWidget {
  final List<String> assetImages = [
    'assets/google.png',
    'assets/icons/apple-logo.png',
  ];

  IconScroller({super.key});

  void handleTap(BuildContext context, int index) async {
    try {
      switch (index) {
        case 0: // Google Sign-In
          await signInWithGoogle();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in with Google')),
          );
          break;

        case 1: // Apple Sign-In
          await signInWithApple();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in with Apple')),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return (await FirebaseAuth.instance.signInWithCredential(credential))
          .user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );

    final authCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    return (await FirebaseAuth.instance.signInWithCredential(authCredential))
        .user;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(assetImages.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: GestureDetector(
              onTap: () => handleTap(context, index),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Image.asset(
                      assetImages[index],
                      fit: BoxFit.contain,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
