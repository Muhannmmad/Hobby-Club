import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FixFavoritesScreen(),
    );
  }
}

class FixFavoritesScreen extends StatefulWidget {
  @override
  _FixFavoritesScreenState createState() => _FixFavoritesScreenState();
}

class _FixFavoritesScreenState extends State<FixFavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFixing = false;
  String message =
      "Press the button to check and correct the favorites structure.";

  Future<void> fixFavoritesStructure() async {
    setState(() {
      isFixing = true;
      message = "Checking and correcting the favorites structure...";
    });

    try {
      final favoritesSnapshot = await _firestore.collection('favorites').get();

      for (var doc in favoritesSnapshot.docs) {
        String userId = doc.id;
        var favoriteData = doc.data();

        // 🟢 Check if userFavorites subcollection exists
        var userFavoritesSnapshot = await _firestore
            .collection('favorites')
            .doc(userId)
            .collection('userFavorites')
            .get();

        List<String> favoritedUsers =
            userFavoritesSnapshot.docs.map((d) => d.id).toList();

        for (String favoritedUserId in favoritedUsers) {
          // Ensure the other user has 'favoritedMe' updated
          await _firestore.collection('favorites').doc(favoritedUserId).set({
            "favoritedMe": FieldValue.arrayUnion([userId])
          }, SetOptions(merge: true));
        }

        print("✅ Fixed favoritedMe for $userId");
      }

      setState(() {
        message = "✅ Favorites structure corrected!";
        isFixing = false;
      });
    } catch (e) {
      print("🔥 Error fixing favorites: $e");
      setState(() {
        message = "❌ Error occurred. Check console for details.";
        isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fix Favorites Structure")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isFixing ? null : fixFavoritesStructure,
              child: isFixing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Fix Favorites"),
            ),
          ],
        ),
      ),
    );
  }
}
