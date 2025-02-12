import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FixFavoritesScreen extends StatefulWidget {
  const FixFavoritesScreen({super.key});

  @override
  FixFavoritesScreenState createState() => FixFavoritesScreenState();
}

class FixFavoritesScreenState extends State<FixFavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isFixing = false;
  String fixStatus = "";

  Future<void> fixFavoritesStructure() async {
    setState(() {
      isFixing = true;
      fixStatus = "Fixing structure...";
    });

    try {
      final querySnapshot = await _firestore.collection('favorites').get();

      for (var doc in querySnapshot.docs) {
        String userId = doc.id;

        if (!doc.exists) continue;

        // Check if this document has a list instead of a subcollection
        var data = doc.data();
        if (data.containsKey('favorites') && data['favorites'] is List) {
          List<dynamic> favoritesList = data['favorites'];

          for (var favUserId in favoritesList) {
            await _firestore
                .collection('favorites')
                .doc(userId)
                .collection('userFavorites')
                .doc(favUserId)
                .set({"timestamp": FieldValue.serverTimestamp()});
          }

          // Remove old incorrect structure
          await _firestore.collection('favorites').doc(userId).update({
            "favorites": FieldValue.delete(),
          });
        }
      }

      setState(() {
        isFixing = false;
        fixStatus = "Favorites structure fixed!";
      });
    } catch (e) {
      setState(() {
        isFixing = false;
        fixStatus = "Error fixing structure: $e";
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
            isFixing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: fixFavoritesStructure,
                    child: const Text("Fix Favorites"),
                  ),
            const SizedBox(height: 20),
            Text(
              fixStatus,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
